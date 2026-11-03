# Question

Solve this question on: `terminal`

The `probe` application exposes three kinds of metrics: the counter `lab_requests_total` (labels `service` and `status`), the histogram `lab_request_duration_seconds` (series `_bucket`, `_sum`, `_count`) and the gauge `lab_queue_depth`. Prometheus scrapes it and loads rule files from the ConfigMap `prometheus-rules`, key `rules.yaml`, which is empty.

Add one rule group with three recording rules that use the right function for each type:

1. `status:lab_requests:rate1m`: the per-second request rate over one minute, one series per `status` value, with no other labels.
2. `lab:request_duration_seconds:p95`: the 95th percentile of request duration in seconds over one minute, computed from the histogram buckets, with no labels.
3. `lab:queue_depth:max`: the highest current value of `lab_queue_depth`, with no labels.

Make Prometheus read the changed file before you submit. Do not change the scrape configuration.

`kubectl` already points at the cluster as the cluster administrator.
