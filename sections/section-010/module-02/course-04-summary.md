---
draft: true
exam_objectives:
- System Architecture
---
# Summary

Alerting is split between two programs. The Prometheus server evaluates alerting rules on a schedule. A rule has an expression, an optional `for` duration, labels and annotations. Each series that the expression returns is one alert, which is pending while the condition has not lasted for the `for` duration and firing after that. An alert goes back to inactive when the expression stops returning it, and the optional `keep_firing_for` field delays that. The server also stores the states as the `ALERTS` series.

Prometheus does not send notifications itself. It posts firing alerts to every Alertmanager that is listed in the `alerting` section of its configuration. A missing or wrong address in that section means that alerts stay in Prometheus. Alertmanager holds its own copy of the alerts and applies four functions before it notifies a receiver. Grouping joins alerts that share the values of the `group_by` labels into one message and uses `group_wait`, `group_interval` and `repeat_interval` to time it. Routing reads the labels of the alert and picks a receiver through the route tree. A silence mutes matching alerts for a period of time. An inhibition rule mutes target alerts while a source alert is firing and the `equal` labels agree.

Debugging an alert therefore follows the chain. First check that the expression returns a series, then the alert state in Prometheus, then the connection to Alertmanager, then the alert list of Alertmanager, and last the routing, silences and receiver. Each step is observed in a different system.

The architecture has extensions for cases that a single scraping server does not cover. The Pushgateway accepts pushed metrics from short-lived batch jobs and keeps them until they are deleted, so it needs `honor_labels` and does not fit long-running services. Remote write sends scraped samples to another system for long-term storage, and remote read lets Prometheus query that system for old data. Federation lets one server scrape a small set of selected series from another through the `/federate` endpoint. Service discovery fills the list of targets from a platform, and for Kubernetes the roles node, pod, service, endpoints, endpointslice and ingress decide what a target is. Choosing the extension that matches the problem keeps the system simple and reliable.

<!-- astrona:playground:destroy -->
