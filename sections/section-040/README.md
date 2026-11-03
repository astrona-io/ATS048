---
draft: true
exam_objectives:
- Data Model and Labels
---
# Data Model and Labels

This section covers the Prometheus data model: how a measurement becomes a sample in a time series, how labels identify a series, and what the four metric types mean. It also covers label design, because every label changes how many series Prometheus must store and how well queries perform.

The first module explains time series, samples, metric names, labels and the reserved `__name__` label. It teaches the naming conventions and the four metric types (counter, gauge, histogram and summary) with the PromQL functions that fit each type: `rate`, `increase`, `sum by` and `histogram_quantile`. The second module explains label matchers, aggregation with `by` and `without`, cardinality, series churn, staleness markers, the labels `up`, `instance` and `job`, and unit conventions. Each module has a playground for free practice and a graded lab. A capstone lab combines both modules in one set of recording rules, and a quiz closes the section.

Read the landing page of each module, then its chapters in order, and finish with the summary. The labs and the quiz appear after the readings they practise.

## Learning Outcomes

- Describe a time series as a metric name plus labels and a sample as a value with a timestamp.
- Explain that the metric name is the label `__name__` and that label names with a `__` prefix are reserved.
- Apply the naming conventions for metrics, labels and recording rules, including base units and `_total`.
- Choose between counter, gauge, histogram and summary, and use `rate`, `increase` and `histogram_quantile` with the correct type.
- Select series with the matchers `=`, `!=`, `=~` and `!~`, and aggregate them with `by` and `without`.
- Calculate cardinality from a label design and explain how unbounded labels cause high memory use and series churn.
- Explain staleness markers and the lookback delta, and use `up`, `instance` and `job` to check targets.
