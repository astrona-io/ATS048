---
draft: true
exam_objectives:
- Data Model and Labels
---
# Summary

Prometheus stores every measurement as a sample, which is a float value with a millisecond timestamp. A sample belongs to a time series, and a series is identified by its metric name together with its full set of labels. Two series that differ in one label value are two separate series. Inside Prometheus the metric name is the label `__name__`, and label names that start with two underscores are reserved for Prometheus. A label with an empty value counts as a label that does not exist.

Names follow conventions that Prometheus does not enforce but every exporter respects. A metric name starts with a one-word prefix for the application, uses base units such as seconds and bytes as a plural suffix, and ends with `_total` when it is a counter. The colon belongs to recording rules only. A label holds a dimension that you can sum across, and the name of a metric never contains the name of one of its labels.

A counter only increases and resets to zero when the process restarts. Its raw value is the total since the start, so you read it with `rate`, which returns the average increase per second and corrects for resets, or with `increase`, which returns the total increase in a window. You take the rate of each series first and aggregate afterwards, for example with `sum by (status)`. A gauge goes up and down, and its current value is meaningful, so you read it directly or aggregate it with `sum`, `avg`, `min` or `max`. `rate` on a gauge returns a number without meaning, because every decrease looks like a reset.

A histogram stores a distribution as cumulative counter series: one `_bucket` series for each upper bound in the label `le`, plus `_sum` and `_count`. The bucket with the bound `+Inf` equals `_count`. You estimate a percentile with `histogram_quantile` on the rate of the buckets, summed by `le`. The estimate interpolates inside one bucket, so its precision depends on the bucket bounds. A summary stores quantiles that the application calculated, in a label `quantile`, plus `_sum` and `_count`. Those quantiles cannot be combined across instances, which is why a histogram is the better choice when you aggregate.

A recording rule evaluates an expression on an interval and stores the result as a new series. By convention its name has the form `level:metric:operations`, where the level lists the labels that the result keeps. Prometheus reads rule files at start and on reload.

The key facts to remember are these:

- A series is a metric name plus labels, and a sample is a value plus a timestamp.
- The type of a metric is metadata. Prometheus does not stop you from using the wrong function.
- Counter: `rate` first, aggregate second. Gauge: read directly. Histogram: `rate`, then `sum by (le)`, then `histogram_quantile`.
- A summary cannot be aggregated across instances. A histogram can.

<!-- astrona:playground:destroy -->
