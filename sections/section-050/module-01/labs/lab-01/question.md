# Question

Solve this question on: `terminal`

The application `exporter` in `starfleet` serves its metrics on `http://exporter:8080/metrics`. It returns the content of the ConfigMap `exporter-metrics`, key `metrics.txt`. Prometheus scrapes it in the job `exporter`, but the target is down.

Edit the page so that Prometheus can parse it. The page must expose these metrics, each with its `# HELP` and `# TYPE` lines:

- a counter `lab_jobs_processed_total` with the labels `queue="default"` and `result="ok"` (value 1027) and `result="error"` (value 13)
- a gauge `lab_workers` with the value 4
- a gauge `lab_queue_length` with the value 7

Do not change the Prometheus configuration. The application reads the file at every request, but a changed ConfigMap reaches the pod with a delay, so make sure the pod serves the new content before you submit.

`kubectl` already points at the cluster as the cluster administrator.
