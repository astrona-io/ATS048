# Question

Solve this question on: `terminal`

Prometheus and Alertmanager run in the `starfleet` namespace. Prometheus scrapes the `probe` application. About one request in ten fails with status 500. Alertmanager listens on the Service `alertmanager`, port 9093, and sends notifications to a webhook receiver. Prometheus does not know about Alertmanager yet, and no alert rule exists.

Make the failures raise an alert that reaches Alertmanager:

1. In the ConfigMap `prometheus-config` (key `prometheus.yaml`), tell Prometheus to send alerts to `alertmanager:9093`. Keep both existing scrape jobs.
2. In the ConfigMap `prometheus-rules` (key `rules.yaml`), add an alerting rule named `LabHighErrorRatio`. It is true when more than five percent of requests fail: the rate of `lab_requests_total` with `status="500"` divided by the rate of all `lab_requests_total`, over one minute. It must hold for 10 seconds before it fires, and carry the label `severity: page`.
3. Make Prometheus read both files.

Do not change the Alertmanager configuration or the workloads.

`kubectl` already points at the cluster as the cluster administrator.
