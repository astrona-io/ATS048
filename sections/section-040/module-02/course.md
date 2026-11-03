---
draft: true
exam_objectives:
- Data Model and Labels
---
# Label Design, Cardinality And Staleness

Labels make Prometheus useful and labels make it expensive. Each label lets you slice a metric by one more dimension. Each new label value creates another time series, and Prometheus holds every active series in memory. A single label with unbounded values, such as a request identifier, can turn one metric into hundreds of thousands of series and slow every query that touches it.

This module covers how to choose labels, how to select and combine series by label, how Prometheus decides that a series has ended, and which labels Prometheus adds to every target. It uses an application that shows the cost of a bad label design on purpose.

## Learning goals

After this module you can:

- Select series with the four label matchers `=`, `!=`, `=~` and `!~`, and explain why regular expressions are fully anchored.
- Aggregate with `by` and `without` and predict which labels the result keeps.
- Define cardinality, calculate the number of series a label design creates and find the metrics that hold the most series.
- Explain series churn and why labels that change with every deployment or request cause it.
- Explain staleness markers and the five-minute lookback, and say what a query returns for a series that has ended.
- Use `up`, `instance` and `job` to see which targets Prometheus scrapes and whether the scrape worked.
- Apply the unit and naming conventions to metrics and labels.

## Before you start

You need to know that a series is a metric name plus labels and that a counter needs `rate`. The module restates every PromQL function it uses. You need `kubectl` and the ability to read YAML.

Your playground is a single-node `kind` cluster that runs Prometheus v3.5.5 in the namespace `starfleet`. It scrapes three targets every two seconds: the application `probe`, Prometheus itself and an application named `crowded`. The `crowded` application exposes the counter `lab_http_requests_total` with two labels. The label `path` has three values: `/orders`, `/cart` and `/search`. The label `request_id` has 100 values for each path. That gives 300 series for one metric, and nobody needs to look at a single request identifier.

The counter in `crowded` never changes after start. Each series holds a fixed value from 1 to 100, which makes sums predictable. A pod named `shuttle` lets you call the Prometheus HTTP API from inside the cluster. The ConfigMap `prometheus-rules` holds an empty rule file for you to fill.

## Reading order

The first chapter covers label matchers and aggregation, which are the two tools for working with labels in queries. The second covers cardinality and series churn, the cost of labels. The third covers staleness, the labels `up`, `instance` and `job`, and unit conventions. The summary closes the module.

Launch your playground now and keep it running next to you while you read:

<!-- astrona:playground -->
