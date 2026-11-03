# Question

Solve this question on: `terminal`

Prometheus in `starfleet` scrapes three jobs from the ConfigMap `prometheus-config` (key `prometheus.yaml`). Two of them are down. The job `probe` targets `probe:8080`. The job `exporter` targets the application `exporter`, which listens on the Service port 8080 and serves valid metrics.

Edit the configuration so that:

1. Both jobs are up.
2. The series `lab_queue_length` from the job `exporter` is not stored. All other series of the exporter stay.
3. Every series of the job `exporter` carries the label `env` with the value `training`.

Do not change the application, and keep the job `prometheus`. Prometheus reads its configuration at start, so make sure the new configuration is loaded before you submit.

`kubectl` already points at the cluster as the cluster administrator.
