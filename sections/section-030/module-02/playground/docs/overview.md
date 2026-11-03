---
draft: true
exam_objectives:
- Understanding Prometheus Limitations
---
# Guided Practice: Cardinality, Gaps And Scrape Limits

This playground runs Prometheus v3.5.5 in the namespace `starfleet`. It scrapes the `probe` application, which a traffic generator calls all the time, and an application named `crowded`. The `crowded` application exposes 200 series of the metric `lab_ticket_info`, one for each open support ticket, with the label `ticket_id`. A `shuttle` pod has `wget` for calls to the Prometheus HTTP API. Nothing here is graded.

The scenario: a support tool team wants Prometheus to count open tickets, and the platform team must make sure the number of tickets can never harm the server. You will measure the cost of the label, add a scrape limit and read the evidence that the limit leaves.

Use a host shell and select the private kubeconfig of this playground. A kubeconfig is a file that tells `kubectl` which cluster to use and how to authenticate.

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-048-playground-030-02)"
kubectl config current-context
```

The current context must be `kind-astro-ats-048-playground-030-02`. If it is another name, stop and select the right kubeconfig.

## Step 1: Metrics against logs

Read the log of the probe and then its metrics page:

```sh
kubectl -n starfleet logs deployment/probe --tail=3
kubectl -n starfleet exec shuttle -- wget -qO- http://probe:8080/metrics
```

Each log line is one request with a request identifier. The metrics page has totals only. Write down one question that the log can answer and the metric cannot, and one question that the metric answers cheaply and the log answers only after counting many lines.

## Step 2: Rate and increase are estimates

Run both functions on the request counter:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=increase(lab_requests_total%5B1m%5D)'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=rate(lab_requests_total%5B1m%5D)'
```

The counter grows in whole numbers, but the `increase` value usually has decimals. Prometheus extrapolates from the first and last sample in the window to the window edges. Compare `increase` with `rate` multiplied by 60 for the same series.

## Step 3: Measure the cost of the label

Look at the metrics page of the `crowded` application and count the series that Prometheus stores for it:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://crowded:8080/metrics
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=count(lab_ticket_info)'
```

The count is 200: one series for each value of `ticket_id`. Read the series count by metric name from the status API of the TSDB. The metric `lab_ticket_info` appears near the top of `seriesCountByMetricName`, and the label `ticket_id` appears in `labelValueCountByLabelName` with 200 values.

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/status/tsdb
```

Ask how many samples each scrape of the job returns and compare it with the probe:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=scrape_samples_scraped'
```

The `crowded` job returns far more samples per scrape than the other jobs. If the ticket system grew to a million tickets, this would become a million series from one application.

## Step 4: Look at gaps with up

Every target has the automatic series `up`. Query it, then read the target list for the last scrape time, duration and error:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=up'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/targets?state=active'
```

All targets are up now, and `lastError` is empty. Remember these fields: after the next step they show how a failed scrape looks.

## Step 5: Add a sample limit

Save the complete ConfigMap with `sample_limit: 100` in the `crowded` job as `prometheus-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: starfleet
data:
  prometheus.yaml: |
    global:
      evaluation_interval: 2s
      scrape_interval: 2s
    rule_files:
    - /rules/*.yaml
    scrape_configs:
    - job_name: probe
      static_configs:
      - labels:
          team: starfleet
        targets:
        - probe:8080
    - job_name: prometheus
      static_configs:
      - targets:
        - localhost:9090
    - job_name: crowded
      sample_limit: 100
      static_configs:
      - targets:
        - crowded:8080
```

Apply it and restart Prometheus so that the new pod reads the file:

```sh
kubectl apply -f prometheus-config.yaml
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

## Step 6: Read the evidence

Wait about fifteen seconds and read the target list again:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/targets?state=active'
```

The target of the job `crowded` is down and `lastError` names the sample limit. The other targets are up, because limits apply per job. Check the series and the counter of rejections:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=count(lab_ticket_info)'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=up%7Bjob%3D%22crowded%22%7D'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=prometheus_target_scrapes_exceeded_sample_limit_total'
```

The first result is empty: the rejected scrapes stored no ticket series. The `up` value is 0. The counter of exceeded limits grows with each scrape. Run the last query twice with a pause to see it grow.

## Step 7: Raise the limit (optional)

Change `sample_limit` to 300 in `prometheus-config.yaml`, apply the file and restart the deployment as before. After about fifteen seconds the `crowded` target is up again, and `count(lab_ticket_info)` returns 200. This shows that the limit compares the number of samples with the limit on every scrape, and the target recovers when it is below it.

## What you should be able to explain

Why does a rejected scrape store no samples at all? Which series proves that the failure happened? Why did the other jobs stay healthy? Which question could a metric never answer about one ticket? What would you alert on so that a rejected target does not look like a quiet one? What does a limit not fix?

## Common pitfalls

> [!WARNING]
> - Confirm the context of this playground before you apply or restart anything.
> - Restart the deployment after you apply the file, or the old configuration keeps running. Read the target list to confirm the new behavior.
> - Do not conclude that the application stopped when a series is missing. Check `up` and `lastError`.
> - The restart empties the `emptyDir` volume, so the older history is gone.
