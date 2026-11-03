---
draft: true
exam_objectives:
- Exposition Format
---
# Summary

Prometheus reads a target through an HTTP response whose body follows the text exposition format. The format is line-oriented: a line feed ends each line, empty lines are ignored, and a line that starts with `#` is a comment unless it is a `# HELP` or `# TYPE` line. Because the parser works line by line, one invalid line fails the whole scrape.

The lines of one metric form a family. The `# HELP` line holds a description, the `# TYPE` line holds the type, and each may appear once per metric. The `# TYPE` line must come before the first sample. A sample line holds a metric name, optional labels, a float value and an optional timestamp in milliseconds. Metric names allow letters, digits, underscores and colons. Label values are always in double quotes, and a backslash, a double quote and a line feed inside them are escaped as `\\`, `\"` and `\n`. Most targets write no timestamp, so Prometheus uses the time of the scrape.

A histogram is written as cumulative `_bucket` lines with an `le` label, plus `_sum` and `_count`. The bucket with `le="+Inf"` is required and has the same value as `_count`. Prometheus does not check this when it parses, but `histogram_quantile` returns `NaN` without it. A summary writes quantile lines with a `quantile` label, plus `_sum` and `_count`, and its quantiles cannot be combined across instances.

The `Content-Type` header selects the parser. The classic text type is `text/plain` with `version=0.0.4`. Since Prometheus 3.0 a missing or unsupported content type fails the scrape. The tool `promtool check metrics` lints a page from standard input, and the field `lastError` in the targets API holds the parser message of a failed scrape.

Key facts to keep:

- A failed scrape sets `up` to 0 and stores no samples from that scrape.
- A value is a float, or `NaN`, `+Inf` or `-Inf`.
- A page without the `+Inf` bucket still parses.
- After a ConfigMap change, the pod may serve the old page until it receives the new content or restarts.

<!-- astrona:playground:destroy -->
