# Overview: Explore OpenMetrics And Format Negotiation (Playground)

This is a playground, not a lab. It starts a fresh cluster and waits. There is no task, no `astrona submit` and no pass or fail. Change the page, watch what Prometheus does and start again with `astrona destroy` when you want a clean state. The steps below are a guided exercise that you can follow in order.

## What is in the environment

- A single-node `kind` cluster with Kubernetes 1.35. `kubectl` already points at it as the cluster administrator.
- Prometheus v3.5.5 in the namespace `starfleet`, with the Service `prometheus` on port 9090. It scrapes every two seconds.
- The `shuttle` pod, which has `wget`. You send requests from it, because the Services are only reachable inside the cluster.
- The `exporter` Deployment, which serves the content of the ConfigMap `exporter-metrics` on `http://exporter:8080/metrics`. Prometheus scrapes it in the job `exporter`. The job sets `scrape_protocols` to `OpenMetricsText1.0.0` first and `PrometheusText0.0.4` second. The application answers with the OpenMetrics content type when the request asks for it, and with the classic text type otherwise.

The page is read at every request. A ConfigMap that is mounted as a volume reaches the pod after a delay of up to about a minute, so restart the Deployment after each change.

## Exercise 1: Compare the two answers

Request the page with the `Accept` header that Prometheus sends, and print the response headers.

```sh
kubectl -n starfleet exec shuttle -- wget -S -qO- --header='Accept: application/openmetrics-text' http://exporter:8080/metrics 2>&1
```

Now request it without the header.

```sh
kubectl -n starfleet exec shuttle -- wget -S -qO- http://exporter:8080/metrics 2>&1
```

Compare the `Content-Type` of the two answers. The body is the same. Write down which parser Prometheus uses for each.

## Exercise 2: Check the result in Prometheus

Query `up` and the counter of the page.

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=up{job="exporter"}'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=lab_jobs_failed_total'
```

The counter family is declared as `lab_jobs_failed` and the series is `lab_jobs_failed_total`. Query `lab_jobs_failed` as well and check that it returns nothing.

## Exercise 3: Remove the # EOF line

Save this as `exporter-metrics.yaml`. It is the same page without the last line.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: exporter-metrics
  namespace: starfleet
data:
  metrics.txt: |
    # HELP lab_jobs_failed Failed jobs by reason.
    # TYPE lab_jobs_failed counter
    lab_jobs_failed_total{reason="timeout"} 5
    lab_jobs_failed_total{reason="oom"} 2
    # HELP lab_job_duration_seconds Job duration in seconds.
    # TYPE lab_job_duration_seconds histogram
    lab_job_duration_seconds_bucket{le="0.1"} 600
    lab_job_duration_seconds_bucket{le="0.5"} 900
    lab_job_duration_seconds_bucket{le="1"} 1000
    lab_job_duration_seconds_bucket{le="+Inf"} 1040
    lab_job_duration_seconds_sum 412.5
    lab_job_duration_seconds_count 1040
```

Apply it and restart the Deployment:

```sh
kubectl apply -f exporter-metrics.yaml
kubectl -n starfleet rollout restart deployment/exporter
kubectl -n starfleet rollout status deployment/exporter
```

Wait a few seconds and read the target:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/targets?state=active'
```

Find the target with `job` set to `exporter`. Its `health` is `down`, and `lastError` says that the data does not end with `# EOF`. Add the line `# EOF` at the end of the `metrics.txt` block, apply the file again, restart and check that `health` returns to `up`.

## Exercise 4: Break the histogram

Remove the line with `le="+Inf"` from the histogram, and keep the `# EOF` line. Apply the file and restart the Deployment. The target is `up`, because the page parses. Now run the quantile query.

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=histogram_quantile(0.9,lab_job_duration_seconds_bucket)'
```

The result is `NaN`. Put the bucket back with the value 1040, apply, restart and query again. A number between 0.5 and 1 returns.

## Exercise 5: Serve a classic page to an OpenMetrics request

Replace the page with a classic text page that has no `# EOF` line. Save this as `exporter-metrics-classic.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: exporter-metrics
  namespace: starfleet
data:
  metrics.txt: |
    # HELP lab_workers Number of running workers.
    # TYPE lab_workers gauge
    lab_workers 4
```

Apply it and restart the Deployment:

```sh
kubectl apply -f exporter-metrics-classic.yaml
kubectl -n starfleet rollout restart deployment/exporter
```

Prometheus still asks for OpenMetrics first, and the application answers with the OpenMetrics type, so the missing `# EOF` fails the scrape. Think about which setting you would change to make this job read the page as classic text. Do not change it in this exercise. The point is that the target decides the content type, and the parser follows it.

## Exercise 6: Add an exemplar line

Start from the full page of the third exercise and put the `# EOF` line back. Change the line of the 0.5 bucket to this:

```text
lab_job_duration_seconds_bucket{le="0.5"} 900 # {trace_id="abc123"} 0.43
```

Apply the file, restart the Deployment and check that `up` is `1`. The OpenMetrics parser reads the exemplar. This installation does not run with the feature flag `exemplar-storage`, so Prometheus does not keep it. Explain why a classic text scrape could not carry the same line.

## Ideas to continue

- Add a `# UNIT lab_job_duration_seconds seconds` line before the `# HELP` line of the histogram and check if the page is still valid.
- Add a line after `# EOF` and read the error.
- Write a blank line at the end of the page and read what the parser reports.

When you are done, run `astrona destroy ats-048-playground-050-02` to remove the environment.
