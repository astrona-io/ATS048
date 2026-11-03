# Question

Solve this question on: `terminal`

A new application, `crowded`, exposes one `lab_ticket_info` series for every open support ticket, and each series has its own `ticket_id` label value. Today there are 200 tickets, and the number grows. Prometheus does not scrape this application yet. The platform team will not let any single target put an unbounded number of series into the time series database.

In the ConfigMap `prometheus-config` (key `prometheus.yaml`), add a scrape job named `crowded` for the target `crowded:8080` with a per-scrape sample limit of 100. With the application as it is, Prometheus must reject the scrape instead of storing part of it. Keep the existing jobs unchanged.

Make Prometheus read the changed file before you submit.

`kubectl` already points at the cluster as the cluster administrator.
