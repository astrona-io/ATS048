# Question

Solve this question on: `terminal`

The application `exporter` in `starfleet` serves the content of the ConfigMap `exporter-metrics`, key `metrics.txt`. It answers with the content type `application/openmetrics-text` when the scraper asks for it. Prometheus asks for OpenMetrics first in the job `exporter`. The target is down.

Edit the page so that it is valid OpenMetrics and complete:

1. The page must end the way the OpenMetrics format requires.
2. The histogram `lab_job_duration_seconds` must be complete. It has 1040 observations in total. Add the bucket that holds all of them.
3. Keep the counter family `lab_jobs_failed` (samples `lab_jobs_failed_total` with `reason="timeout"` 5 and `reason="oom"` 2) and all other lines unchanged.

Do not change the Prometheus configuration. Make sure the pod serves the new content before you submit.

`kubectl` already points at the cluster as the cluster administrator.
