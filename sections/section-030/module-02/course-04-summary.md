---
draft: true
exam_objectives:
- Understanding Prometheus Limitations
---
# Summary

Prometheus stores numeric measurements over time. It does not store the content of events. A log records one event, a trace records the path of one request, and a metric summarises many events in a number whose storage cost does not grow with the number of events. Adding a request or user identifier as a label to get per-event detail creates one series per value and exhausts the memory of the server.

The numbers that Prometheus keeps are estimates. The server sees a counter only at scrape time, a failed scrape leaves a gap, and a restart of the application resets a counter. The functions `rate()` and `increase()` extrapolate from the first and last sample in the window to the window edges, so a result can have decimals for a counter that only grows in whole numbers. This is accurate enough for dashboards and alert thresholds. It is not suitable for billing or any figure that must be exact for each event.

The pull model means that Prometheus must be able to reach each target over HTTP while the target runs. Targets behind a firewall, short-lived jobs and processes without an HTTP endpoint need another approach, such as the Pushgateway for the results of batch jobs. The automatic series `up` separates a failed scrape from a quiet target. Queries return the newest sample within a lookback period of five minutes by default, and staleness markers end a series earlier when a target is removed or a series stops being returned.

Long-term and shared storage lives outside the server. Remote write sends a copy of each sample to a separate system while the local database keeps its own short retention, and it does not make Prometheus a cluster. Alert delivery is not guaranteed end to end: rule evaluation, the send to Alertmanager and the notification to the receiver can each fail. The remedy is to monitor the pipeline, run an HA pair and keep an alert that always fires to detect silence.

The per-job limits protect the server from a target that sends too much. When a scrape exceeds `sample_limit`, or breaks a label limit, Prometheus treats the whole scrape as failed and stores none of its samples. The target is marked down, `up` is 0 and a counter records the rejection. Other jobs are not affected. The limit is a safety net; the real fix is to remove the label that grows without a bound.

<!-- astrona:playground:destroy -->
