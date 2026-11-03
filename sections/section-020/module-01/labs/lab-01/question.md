# Question

Solve this question on: `terminal`

Prometheus in the `starfleet` namespace reads its configuration from the ConfigMap `prometheus-config`, key `prometheus.yaml`. The job `probe` should scrape the `probe` Service, but the target never becomes healthy.

Fix and tune the job `probe`. Change nothing else in the file.

1. Make the target healthy. The `probe` Service exposes its metrics on port 8080 at the default path.
2. Give only this job a scrape interval of 5 seconds and a scrape timeout of 3 seconds. The global interval stays at 2 seconds.
3. Attach the label `env` with the value `lab` to every series of this job by setting it on the target group.

Make Prometheus read the changed file before you submit.

`kubectl` already points at the cluster as the cluster administrator.
