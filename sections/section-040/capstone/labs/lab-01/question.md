# Question

Solve this question on: `terminal`

Prometheus in `starfleet` scrapes two applications. `probe` exposes the counter `lab_requests_total` (labels `service` and `status`) and the histogram `lab_request_duration_seconds`. `crowded` exposes the counter `lab_http_requests_total` with the labels `path` (three values) and `request_id` (100 values per path). The ConfigMap `prometheus-rules`, key `rules.yaml`, is empty.

Add one rule group with four recording rules:

1. `job:lab_requests:rate1m`: the per-second rate of `lab_requests_total` over one minute, summed per `job`, with no other labels.
2. `lab:requests_failed:rate1m`: the same rate for the series whose `status` starts with 5 (use a regular expression matcher), summed to one series without labels.
3. `path:lab_http_requests:sum`: the sum of `lab_http_requests_total` per `path`, with no other labels.
4. `lab:request_duration_seconds:p90`: the 90th percentile of request duration in seconds over one minute from the histogram buckets, with no labels.

Make Prometheus read the changed file before you submit. Do not change the scrape configuration.

`kubectl` already points at the cluster as the cluster administrator.
