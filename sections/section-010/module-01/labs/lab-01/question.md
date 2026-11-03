# Question

Solve this question on: `terminal`

Prometheus runs in the `starfleet` namespace and scrapes the `probe` application every two seconds. Prometheus already loads rule files from `/rules/*.yaml`. That directory comes from the ConfigMap `prometheus-rules`, key `rules.yaml`, which holds an empty list of groups.

Add one rule group to that file with two recording rules:

1. `job:lab_requests_total:rate1m` records the per-second request rate over one minute, summed over all label sets of `lab_requests_total`, keeping only the `job` label.
2. `job:lab_requests_errors:ratio_rate1m` records the share of requests that failed: the rate of `lab_requests_total` with `status="500"` divided by the rate of all `lab_requests_total`, both summed by `job`.

Do not change the scrape configuration or the `probe` workload. Prometheus reads rule files at start and on reload, so make it read the changed file before you submit.

`kubectl` already points at the cluster as the cluster administrator.
