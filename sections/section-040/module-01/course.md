---
draft: true
exam_objectives:
- Data Model and Labels
---
# Time Series, Samples And Metric Types

Prometheus stores every measurement as a sample that belongs to a time series. A time series is identified by a metric name and a set of labels. Every question you ask Prometheus later, from a dashboard query to an alerting rule, reads series by their name and labels. If you do not know how a series is identified, you cannot predict what a query returns, why two series merge or why a graph shows two lines instead of one.

The second half of the module covers metric types. An application declares each metric as a counter, a gauge, a histogram or a summary. The type tells you what the number means and which PromQL function is correct for it. A counter needs `rate`, a gauge is read as it is, and a histogram needs `histogram_quantile`. Using the wrong function does not cause an error. It returns a wrong number, which is the reason this module spends time on it.

## Learning goals

After this module you can:

- Describe a time series as a metric name plus labels, and a sample as a value with a timestamp.
- Explain that the metric name is the label `__name__` and that labels with a `__` prefix are reserved for Prometheus.
- Apply the naming conventions for metrics and labels, including `_total`, base units and the suffixes of histograms.
- Choose between counter, gauge, histogram and summary for a given measurement.
- Use `rate`, `increase`, `sum by` and `histogram_quantile` with the right metric type.
- Write recording rules whose names say which labels the result keeps and which operations were applied.

## Before you start

You need to know what a metric is in general terms and to be able to read YAML and run `kubectl` commands. You do not need to know PromQL. The module introduces each function when it is used.

Your playground is a single-node `kind` cluster that runs Prometheus v3.5.5 in the namespace `starfleet`. It also runs the example application `probe`, a traffic generator that sends one request to `probe` every quarter of a second, and a pod named `shuttle` that you use to call the Prometheus HTTP API. Prometheus scrapes `probe` every two seconds in the job `probe`.

The `probe` application exposes these metrics:

| Metric | Type | Meaning |
| --- | --- | --- |
| `lab_requests_total` | counter | Completed requests, with the labels `service` and `status` |
| `lab_queue_depth` | gauge | Current number of queued items |
| `lab_last_success_timestamp_seconds` | gauge | Unix time of the last successful request |
| `lab_request_duration_seconds` | histogram | Request duration, as `_bucket`, `_sum` and `_count` series |

The Prometheus rule files come from the ConfigMap `prometheus-rules` and start empty. `kubectl` already points at the playground cluster.

## Reading order

The first part shows what a series, a sample and a label are, and which names are allowed. The second part covers counters and gauges and the functions that fit them. The third part covers histograms and summaries, estimates a percentile and writes recording rules. The summary closes the module.

Launch your playground now and keep it running next to you while you read:

<!-- astrona:playground -->
