# Question

Solve this question on: `terminal`

An alerting pipeline in `starfleet` was set up by a colleague, and no notification has ever arrived. The parts are: Prometheus, Alertmanager (Service `alertmanager`, port 9093) and a webhook receiver that is part of the `probe` application at `http://probe:8080/hooks`. About one request in ten to `probe` fails with status 500.

The alert `LabHighErrorRatio` must fire when more than five percent of requests fail, carry the label `severity: page`, and end up as a notification at the webhook receiver.

Find and fix every fault so that a notification for `LabHighErrorRatio` reaches the webhook. The faults are in the ConfigMaps `prometheus-config` (key `prometheus.yaml`) and `prometheus-rules` (key `rules.yaml`). Do not change the Alertmanager configuration or the workloads.

`kubectl` already points at the cluster as the cluster administrator.
