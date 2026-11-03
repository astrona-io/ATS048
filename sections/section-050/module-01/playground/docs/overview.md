# Overview: Explore The Text Exposition Format (Playground)

This is a playground, not a lab. It starts a fresh cluster and waits. There is no task, no `astrona submit` and no pass or fail. Read pages, break them, repair them and start again with `astrona destroy` if you want a clean state. The steps below are a guided exercise that you can follow in order or skip around in.

## What is in the environment

- A single-node `kind` cluster with Kubernetes 1.35. `kubectl` already points at it as the cluster administrator.
- Prometheus v3.5.5 in the namespace `starfleet`, with the Service `prometheus` on port 9090. It scrapes every target every two seconds.
- The `probe` application, which serves its own metrics page on `http://probe:8080/metrics`, and a traffic generator that sends requests to it.
- The `shuttle` pod, which has `wget`. You run requests from it, because the Services are only reachable inside the cluster.
- The `exporter` Deployment, which serves the content of the ConfigMap `exporter-metrics` on `http://exporter:8080/metrics`. Prometheus scrapes it in the job `exporter`. The Deployment answers in the classic text format, with the content type `text/plain; version=0.0.4`.

The `exporter` reads its file at every request. A ConfigMap that is mounted as a volume reaches the pod after a delay of up to about a minute, so after each change you restart the Deployment to skip the wait.

## Exercise 1: Read a real page

Request the page of the `probe` application and read it from top to bottom.

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://probe:8080/metrics
```

For each family, name the type from the `# TYPE` line and say which suffixes the lines use. Find the counter that ends in `_total`, the gauge for the queue and the histogram for the request duration. Count the `_bucket` lines of the histogram and find the one with the bound `+Inf`. The numbers change with traffic, so compare the structure and not the values.

## Exercise 2: Read the exporter page

Request the page of the `exporter`.

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://exporter:8080/metrics
```

Count the sample lines and note the metric names. Then ask Prometheus whether the last scrape worked.

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=up{job="exporter"}'
```

The value is `1` when the page parsed. Query the number of samples that the page held and compare it with the number of sample lines you counted.

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=scrape_samples_scraped{job="exporter"}'
```

## Exercise 3: Break the page on purpose

Save this as `exporter-metrics.yaml`. It changes the ConfigMap so that the label value of the first sample has no quotes.

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
    lab_jobs_failed_total{reason=timeout} 5
    lab_jobs_failed_total{reason="oom"} 2
```

Apply it and restart the Deployment so that the new pod serves it:

```sh
kubectl apply -f exporter-metrics.yaml
kubectl -n starfleet rollout restart deployment/exporter
kubectl -n starfleet rollout status deployment/exporter
```

Wait a few seconds for the next scrape, then read the target state:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/targets?state=active'
```

Find the target with `job` set to `exporter`. The field `health` is `down` and the field `lastError` holds the parser message. Note the line number that it names. Check `up` again: the value is `0`.

## Exercise 4: Fix it one fault at a time

Edit `exporter-metrics.yaml` and put quotes around `timeout`. Apply the file, restart the Deployment and read `lastError` again. When `health` returns to `up`, try these changes one by one, and each time predict the error before you read it:

1. Change the value of the second sample to the word `two`.
2. Rename the metric of the second sample to `lab-jobs-failed_total`.
3. Add a second line `# TYPE lab_jobs_failed counter` after the first sample.

Each change shows a different message. The point is to learn which message belongs to which rule, so that you recognise it in a real failure.

## Exercise 5: Escape a label value

Add this line at the end of the page and apply the change as before.

```text
lab_files_total{path="C:\\data",note="said \"stop\""} 2
```

Query the series in Prometheus and read the labels of the result.

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=lab_files_total'
```

The answer shows the labels as the parser read them, with the escapes turned into the real characters in the JSON. Change a backslash to a single one, as in `C:\data`, and see what the parser does with it.

## Exercise 6: Remove the +Inf bucket

Write a page with a histogram that has the buckets `0.1`, `0.5` and `1`, the lines `_sum` and `_count`, and no `+Inf` bucket. Apply it and restart the Deployment. `up` stays `1`, because the page parses. Now compute a quantile:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=histogram_quantile(0.9,lab_job_duration_seconds_bucket)'
```

The result is `NaN`. Add the bucket `lab_job_duration_seconds_bucket{le="+Inf"}` with the same value as `_count`, apply it, restart and query again. A number returns.

## Exercise 7: Lint a page with promtool

The Prometheus image contains `promtool`. Send the page of the `exporter` to its linter.

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://exporter:8080/metrics | kubectl -n starfleet exec -i deploy/prometheus -- promtool check metrics
```

Now remove the `# HELP` line of one metric, or rename a counter so that it has no `_total` suffix, and run the pipe again. Read what the linter reports and compare it with what Prometheus reported for the same page.

## Exercise 8: Look at the headers

Print the response headers of the `exporter`.

```sh
kubectl -n starfleet exec shuttle -- wget -S -qO- http://exporter:8080/metrics 2>&1
```

Find the header `Content-Type` and the version in it. Compare it with the headers of the `probe`.

## Ideas to continue

- Add a timestamp in milliseconds at the end of one sample line and see how the series appear in a query with a range.
- Write a summary family with three quantiles and query the series. Check that the quantile is a label.
- Stop the `exporter` Deployment with `kubectl -n starfleet scale deployment/exporter --replicas=0` and read the `lastError` for a target that does not answer. Scale it back to 1 afterwards.

When you are done, run `astrona destroy ats-048-playground-050-01` to remove the environment.
