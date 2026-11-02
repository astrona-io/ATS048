---
draft: true
exam_objectives:
- Understanding Prometheus Limitations
---
# Prometheus Storage, Scale And Evidence Limits

Prometheus is designed for operational monitoring and alerting using numerical time series. Its usefulness depends on what producers expose, what scrapes collect and how long data remains available. Understanding its limits prevents assigning certainty to a dashboard that the underlying evidence cannot support.

## Collection Is Not A Complete Event Ledger

A scrape observes metric state at a point in time. Counters can preserve accumulated events between scrapes while the process retains them, but a process can restart or disappear before its final state is collected. Missing scrapes and changed series identity can leave gaps. Rate functions handle visible counter resets according to their model; they cannot reconstruct every event that was never represented in collected samples.

Metrics therefore should not be the sole source for exact billing, legal transaction accounting or a complete request audit. Those tasks require authoritative records with appropriate delivery and reconciliation guarantees. Prometheus can still monitor the health of those systems and compare aggregate behavior, provided its operational role is clear.

## Cardinality Drives Cost

Each unique metric name and label set creates a series. Adding a bounded status label may be useful, while adding every request ID or user ID can create an enormous and constantly changing series population. The cost includes memory, ingestion, indexing, storage and queries. Aggregating the result in a dashboard does not erase the cost of collecting all source series.

Series churn also matters. Rapid creation and disappearance of instance identities can stress the system even when the number of currently active series appears moderate. Assess both active cardinality and lifecycle behavior. Use logs or traces for unbounded event-specific context rather than placing that detail in metric labels by default.

## Local History Has A Storage Contract

Local retention determines how much history remains available under the configured time or size limits. Available disk capacity, ingestion rate and block maintenance affect the practical result. A longer requested retention is not a guarantee if storage is insufficient. Recent data and persisted blocks have different operational behavior, so recovery planning should match the supported storage mechanisms.

Prometheus local storage is not automatically a distributed replicated database. Independent replicas can scrape the same targets for resilience, but their samples and gaps can differ. A downstream query layer may need explicit deduplication when combining replica data. Simply adding two copies can double-count a measurement rather than improve its meaning.

## Remote Systems Add Dependencies

Remote write can extend a deployment with another storage destination, but it introduces queues, retries, limits and receiver behavior. A healthy local scrape does not establish that the remote system has current data. The remote system's retention and query guarantees are also separate from local configuration.

Broad queries across many series and long ranges can be expensive. Recording rules can materialize common derived expressions, but their own evaluation and retention must be considered. A precomputed series cannot recover missing source observations or answer every new historical grouping question.

## Monitor The Monitoring Path

The collector's health, scrape coverage, rule evaluation and storage or delivery failures affect confidence in application observations. A quiet alert dashboard can mean healthy services or failed monitoring. Use evidence about the monitoring path itself and avoid circular assumptions that the absence of application alerts proves the collector is functioning. State the time range and collection limitations when interpreting results.

## Common pitfalls

> [!WARNING]
> Operational metrics are not a complete transaction ledger. High cardinality costs remain even after aggregation, and remote storage or replicas do not provide automatic deduplication or complete history.
