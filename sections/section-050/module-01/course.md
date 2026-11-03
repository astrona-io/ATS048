---
draft: true
exam_objectives:
- Exposition Format
---
# The Text Exposition Format

Prometheus collects data by sending an HTTP request to a target and reading the response body. The body must follow a fixed layout, called the exposition format. If the body breaks the layout, Prometheus rejects the scrape and the target shows as down. This module teaches the classic text exposition format, line by line, so that you can read any metrics page and repair one that does not parse.

## Learning goals

After this module you can:

- Read a metrics page and name the role of every line: `# HELP`, `# TYPE` and sample lines.
- Write a valid sample line with labels, escaped label values, a float value and an optional timestamp.
- Explain how a histogram is written with `_bucket`, `_sum` and `_count` lines, why the `+Inf` bucket is required, and how a summary writes quantiles.
- Name the content type that a target must return and what Prometheus does when it is missing.
- Check a page with `promtool check metrics` and read the parse error that Prometheus stores for a failed scrape.

## What you should know first

You should know that Prometheus scrapes targets over HTTP on a fixed interval, that a metric has a name and labels, and that the four metric types are counter, gauge, histogram and summary. The module explains each of these again where the format depends on it.

## How the module is organised

The first lesson covers the building blocks of the format: metric families, metadata lines, sample lines, labels, escaping, values and timestamps. The second lesson covers the two types that need several lines each, the histogram and the summary. The third lesson covers the HTTP side, which is the content type and the version of the format, and then the tools and error messages you use to find a fault in a page.

The playground for this module runs Prometheus v3.5.5 in the namespace `starfleet`, the `probe` application that serves a metrics page, a `shuttle` pod with `wget`, and an `exporter` Deployment that serves a page from a ConfigMap. You can request each page, change the ConfigMap and watch how Prometheus reacts. The graded lab for this module gives you a page that Prometheus cannot parse and asks you to fix it.

<!-- astrona:playground -->
