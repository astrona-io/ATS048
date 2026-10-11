---
draft: true
exam_objectives:
- Exposition Format
---
# Reading Metric Exposition And Format Contracts

A metrics endpoint exposes values in a format that the scraper can parse. The familiar Prometheus text format groups related metrics through naming and optional metadata, then presents sample lines with values and labels. Understanding the wire contract helps distinguish a healthy endpoint from a response that looks readable but cannot be ingested correctly.

## Metadata Describes Metric Families

HELP text describes the measured quantity, while TYPE declares a family's metric type. A counter represents accumulation, a gauge represents a value that can move in either direction, and distributions have additional structure. Metadata should be consistent with the emitted samples. A family described as a counter should not expose a value that arbitrarily decreases as normal business behavior.

Sample lines identify a metric, optional labels and a numerical value. A conceptual line such as queue_depth{queue="payments"} 7 means the gauge has value seven for that label set. The example explains syntax; it is not recorded output from an executed system. The label set contributes to series identity, so duplicate conflicting entries for the same series in one snapshot are not a sound exposition design.

## Escaping And Structure Matter

Label values are strings within a structured format and require appropriate escaping for characters such as quotes, backslashes and newlines. HELP text has its own escaping rules. A library normally handles these details. Hand-building response text increases the risk that a valid-looking payload fails parsing or gives an unintended label value.

Classic histograms expose related bucket, sum and count series, with bucket boundaries represented by the le label. Their bucket counts are cumulative. Summaries also expose sum and count but can include quantile estimates computed by the producer. Naming and metadata must identify those relationships consistently. Treating a bucket as an independent event type loses the distribution contract.

## Separate Value And Sample Timestamp

A text sample can have an explicit timestamp where the format supports it, but ordinary application exposition generally lets the scraper assign collection time. Supplying timestamps changes freshness and ingestion behavior and needs a clear reason. The units of an explicit wire timestamp follow that format's specification rather than the metric's chosen unit.

A metric whose value is a Unix timestamp is different. For example, last_success_timestamp_seconds describes the time of a successful operation, while the sample timestamp says when that value was observed. The collector can scrape a recent sample whose contained event time is old. That distinction enables alerts about overdue work without claiming the scrape itself was stale.

## Content Negotiation And Format Differences

Prometheus and OpenMetrics formats have related concepts but different requirements and capabilities. Content type and negotiation identify the supported representation. OpenMetrics can include features such as exemplars and a defined end marker. Native histogram transport and support also depend on the selected format and compatible producer and collector versions.

Do not assume that copying a short classic text example creates a complete OpenMetrics response. Prefer maintained client libraries and verify the intended collector's supported formats. The absence of TYPE metadata in a permissive format does not make all samples correctly instrumented; users still need the measurement's semantic contract.

## Diagnose Parsing Separately

An HTTP success status does not establish successful ingestion if the response is malformed or uses an unsupported representation. Review content type, syntax, family consistency and sample identity separately from network reachability. A successful scrape then establishes an accepted snapshot, while application health remains a different question.

## Common pitfalls

> [!WARNING]
> Escaping is not encryption. Metric event-time values differ from sample timestamps, and a classic text response must not be assumed to satisfy every OpenMetrics or native-histogram contract.
