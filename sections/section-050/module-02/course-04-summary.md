---
draft: true
exam_objectives:
- Exposition Format
---
# Summary

Prometheus and a target agree on a format for every scrape. Prometheus sends an `Accept` header that the field `scrape_protocols` builds, in order of preference. The target chooses one format and names it in the `Content-Type` header of the response. Prometheus picks the parser from that header and never from the content of the body. For this reason one page can be valid under the classic text type and fail under the OpenMetrics type.

OpenMetrics is stricter than the classic text format. A page must end with the line `# EOF`, and nothing may follow it, so a truncated page is never mistaken for a complete one. A counter family is declared by its name without a suffix, and its samples carry the suffix `_total`. Counters, histograms and summaries may carry `_created` samples. Timestamps are in seconds. An optional `UNIT` line names the unit, and the types StateSet, Info and GaugeHistogram exist only in OpenMetrics.

A histogram needs a bucket with `le="+Inf"` whose value equals `_count`. Prometheus does not check this when it parses a page. The target stays up, and `histogram_quantile` returns `NaN` without the bucket. An exemplar is an example observation with a trace identifier that follows a sample after a `#` character. Only OpenMetrics carries it, and Prometheus keeps it only with the feature flag `exemplar-storage`. A native histogram stores a whole distribution with exponential buckets in one series. It travels in the Protocol Buffers format, so the scrape must negotiate `PrometheusProto`.

A client library keeps a registry of metrics, escapes values, completes histograms and chooses the format from the request, so most faults come from hand-written pages. A custom exporter receives the request, reads the source at request time, renders the page and answers with the right content type. The Pushgateway accepts text format pages on a path with the job name and a grouping key. A `PUT` replaces the group, a `POST` replaces only the metrics it names, and a `DELETE` removes the group. Pushed data stays until someone removes it.

Key facts to keep:

- The first error in `lastError` is not always the only one. Fix it, wait for the next scrape and read again.
- Network, timeout, status, content type and body errors each point to a different layer.
- A ConfigMap change reaches a running pod with a delay, so restart the Deployment when you need the new page at once.

<!-- astrona:playground:destroy -->
