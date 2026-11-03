# Question

Solve this question on: `terminal`

The application `exporter` in `starfleet` serves the content of the ConfigMap `exporter-metrics`, key `metrics.txt`, in the classic Prometheus text format on `http://exporter:8080/metrics`. Prometheus scrapes it in the job `exporter`, and the target is down.

The page must expose:

- the counter `lab_jobs_processed_total` with `queue="default"` and `result="ok"` (1027) and `result="error"` (13)
- the gauge `lab_workers` with the value 4
- the histogram `lab_task_duration_seconds` with 1040 observations in total, and the buckets that the page already has

Repair the page so that it parses and every metric is complete. Do not change the Prometheus configuration. Make sure the pod serves the new content before you submit.

`kubectl` already points at the cluster as the cluster administrator.
