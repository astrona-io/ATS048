---
draft: true
exam_objectives:
- Data Model and Labels
---
# Summary

A metric name and label set identify a time series; label values are dimensions rather than descriptive text detached from identity. Changing labels creates new series and can increase cardinality or churn.

Missing observations and stale series are different from measured zero. Matchers that accept empty values can include absent labels, so query interpretation must account for both identity and the available evidence.
