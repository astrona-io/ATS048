---
draft: true
exam_objectives:
- Data Model and Labels
---
# Summary

A selector chooses series by metric name and label matchers. The four matchers are `=`, `!=`, `=~` and `!~`. A regular expression must match the whole label value, because Prometheus anchors it at both ends, so a prefix needs `.*`. Every selector needs a metric name or one matcher that cannot match an empty string. The metric name is the label `__name__`, so you can also select by a name pattern.

An aggregation operator combines many series into fewer. Without a clause the result has no labels. With `by` the result keeps only the listed labels, and with `without` it keeps all labels except the listed ones. `sum` adds sample values and `count` counts series. An aggregation shows fewer series but does not remove the input. The raw series stay in memory. A recording rule stores the aggregated result once for each evaluation interval, so queries read the small result.

The cardinality of a metric is its number of series, and with independent labels it is the product of the label cardinalities. Prometheus keeps all active series in the head block in memory, so cardinality sets the memory use and the speed of queries. You measure it with `count`, with `prometheus_tsdb_head_series`, with `scrape_samples_scraped` for one target and with the status API of the database. A label belongs on a metric only when someone filters or groups by it, when its values are bounded and when the sum over its values has a meaning. Request identifiers, user names and client addresses do not meet these tests.

Series churn is the rate at which series appear and end. A label whose value changes with each deployment or request starts new series and leaves old ones behind. Churn raises memory use, slows long queries and breaks the continuity of graphs. Descriptive values that change rarely belong in an info metric. A label that already causes trouble can be dropped at scrape time with `labeldrop`, as long as the remaining labels keep every series unique.

Prometheus ends a series with a staleness marker. It writes a marker when a scrape no longer contains the series, when a target is removed or its scrape fails, and when a recording rule stops returning a series. A marker is not a zero. After it, queries return no value. When there is no marker, a query returns the newest sample inside the lookback delta, which is five minutes by default.

Prometheus adds the labels `job` and `instance` to every series from a target. `job` is the name of the scrape configuration entry, and `instance` is by default the address with the port. After each scrape it also writes the series `up`, which is 1 for a successful scrape and 0 for a failed one. The expression `up == 0` is the standard check for a target that is down.

Names and units follow conventions. Metrics use base units as a suffix, such as `_seconds` and `_bytes`, and counters end in `_total`. Labels are lowercase with underscores and never hold units or lists. Colons belong to recording rule names of the form `level:metric:operations`.

The key facts to remember are these:

- Regular expression matchers are fully anchored.
- `by` keeps listed labels and `without` drops listed labels.
- Series count equals the product of label cardinalities, and unbounded labels cause both high cardinality and churn.
- A stale series returns no value, and a missing series is not a zero.
- `up` is 1 or 0 for each target, labelled with `job` and `instance`.

<!-- astrona:playground:destroy -->
