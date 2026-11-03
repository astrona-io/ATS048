---
draft: true
exam_objectives:
- Exposition Format
---
# Exposition Format

Prometheus collects metrics by sending an HTTP request to a target and parsing the response body. This section teaches the format of that body. The first module covers the classic text exposition format: metric families, `# HELP` and `# TYPE` lines, sample lines, label escaping, timestamps, histograms, summaries, the content type and the tools and errors you use to repair a page. The second module covers OpenMetrics and its negotiation with the classic format, exemplars and native histograms as concepts, client libraries, the Pushgateway and the errors of a failed scrape.

Each module has a landing page, three lessons and a summary. Each module has a playground, an environment without a task where you can change a metrics page and watch Prometheus react, and a graded lab that gives you a broken page to repair. A capstone lab at the end of the section combines both modules in one page that has a text fault and an incomplete histogram.

## Learning outcomes

After this section you can:

- Read a metrics page and name the role of each `# HELP`, `# TYPE` and sample line.
- Write valid sample lines with quoted and escaped label values, float values and optional timestamps.
- Write a complete histogram with cumulative `_bucket` lines, `_sum`, `_count` and a `+Inf` bucket, and explain what happens to `histogram_quantile` without it.
- Write a summary with quantile lines and explain why its quantiles cannot be combined.
- State the content types of the classic text format and of OpenMetrics, and explain how the `Accept` header, `scrape_protocols` and the response `Content-Type` decide the parser.
- Name what OpenMetrics adds: the `# EOF` line, the `_total` and `_created` suffixes, units and exemplars.
- Describe native histograms and exemplars, and say which format and which setting each one needs.
- Check a page with `promtool check metrics` and read `lastError` in the targets API.
- Explain what a client library does and how a small exporter and the Pushgateway deliver metrics.
- Match a scrape error to a network, timeout, status, content type or body cause.
