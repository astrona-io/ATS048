# Question

Solve this question on: `terminal`

Prometheus in the `starfleet` namespace scrapes the `probe` Service in the job `probe`. The configuration is in the ConfigMap `prometheus-config`, key `prometheus.yaml`. Change only the job `probe`, using relabeling.

1. Before the scrape, set the label `instance` of the target to the constant `probe-main`, instead of `probe:8080`.
2. Before the scrape, add the label `tier` with the constant value `backend` to the target, so that every series of the job has it.
3. After the scrape, drop the metric `lab_queue_depth` so that it is not stored. Every other metric of the job must stay.

Make Prometheus read the changed file before you submit.

`kubectl` already points at the cluster as the cluster administrator.
