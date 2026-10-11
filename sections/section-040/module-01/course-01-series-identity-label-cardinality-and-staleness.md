---
draft: true
exam_objectives:
- Data Model and Labels
---
# Series Identity, Label Cardinality And Staleness

Prometheus stores labeled time series. A series is identified by its metric name and label set, and each sample associates a timestamp with a value. This identity model supports grouping and filtering, but also determines how many distinct series the system must maintain and how continuity behaves when labels change.

## Labels Are Dimensions Of Identity

A request counter might have service, route and status labels. Each observed combination belongs to a separate series. Two samples with the same metric name but different status values are not two values of one unlabeled series; they are observations of different labeled series. Queries can later aggregate those dimensions when an overview is needed.

The metric name describes the measured quantity, while label keys and values describe dimensions. Avoid using labels to encode unrelated measurement types with incompatible units. A value called temperature should not sometimes mean bytes because a label changes. Clear quantity and unit semantics make arithmetic and aggregation meaningful.

## Bound The Label Space

If there are five routes and four status groups, their combinations can already produce up to twenty series per remaining label combination. Additional instance and environment labels multiply that space. Not every theoretical combination must be emitted, but the product is a useful planning signal. An unbounded request identifier can create a new series for every request and destroy that bounded model.

Use normalized route templates rather than raw URLs containing IDs where appropriate. A user-specific identifier often belongs in a log or trace, with suitable confidentiality controls. High cardinality increases ingestion and query cost even if a dashboard eventually sums all series into one line.

## Changes Create New Series

Changing a label value changes series identity. A replaced target with a new instance label can produce new series while historical samples for the old identity remain within retention. Queries grouped by service can combine instances, but that does not mean the database rewrote old labels. Preserve stable ownership dimensions where they serve a defined need.

Rapid changes can create churn independently of the active population. A system that replaces thousands of label combinations every minute can impose indexing and storage work even if only a subset is currently active. Review the lifecycle of labels, not merely a snapshot of current values.

## Matchers Have Empty-Value Semantics

Selectors can use equality, inequality and regular-expression matchers. A matcher that accepts an empty value can also match series where that label is absent. For example, excluding one named environment does not necessarily require that an environment label exist. If presence matters, the query must express an appropriate non-empty condition as well.

Regular-expression matchers are anchored to the full label value. A pattern intended to match a substring must explicitly allow surrounding characters. These semantics affect which population an aggregation includes, so test the meaning of the selector before interpreting its result as a complete fleet total.

## Absence Is Not Zero

An instant selector uses eligible samples under the query's lookback and staleness behavior. A series that stopped producing data can disappear from a current result while its historical samples remain available. That is different from a currently observed value of zero. Substituting zero indiscriminately can hide a collection outage or turn missing evidence into a false healthy result.

## Common pitfalls

> [!WARNING]
> Labels define identity and cardinality. A matcher accepting empty values can include absent labels, and a missing current series must not be treated as measured zero without a justified model.
