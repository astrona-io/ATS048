---
draft: true
exam_objectives:
- Exposition Format
---
# OpenMetrics, Client Libraries And Scrape Errors

The classic text format is not the only format that Prometheus reads. OpenMetrics is a stricter standard that grew out of the text format, and Prometheus negotiates between the two with each scrape. This module explains how the negotiation works, what OpenMetrics adds, how applications produce a page with client libraries, how the Pushgateway accepts data, and how to read the errors of a failed scrape.

## Learning goals

After this module you can:

- Explain how Prometheus asks for a format with the `Accept` header and the field `scrape_protocols`, and how the target answers with its content type.
- Name the differences between classic text and OpenMetrics: the `# EOF` line, the `_total` and `_created` suffixes, the `UNIT` line and exemplars.
- Describe exemplars and native histograms as concepts and say which feature flags and formats they need.
- Describe what a client library does when you instrument an application, and the steps of a small custom exporter.
- Describe the data that the Pushgateway accepts and how its page is exposed.
- Match a scrape error to its cause: unreachable target, status code, content type, parse error, missing `# EOF`.

## What you should know first

You should know the text format: `# HELP` and `# TYPE` lines, sample lines with quoted label values, and histograms with `_bucket`, `_sum` and `_count` and a `+Inf` bucket. The module repeats the facts it relies on.

## How the module is organised

The first lesson covers format negotiation and the OpenMetrics rules for counters and the end of the page. The second lesson covers histograms in OpenMetrics, the `histogram_quantile` result when a bucket is missing, exemplars and native histograms. The third lesson covers client libraries, a small exporter, the Pushgateway and a table of scrape errors.

The playground runs Prometheus v3.5.5 in the namespace `starfleet`, the `shuttle` pod with `wget`, and an `exporter` Deployment that serves a page from a ConfigMap. In this module the job `exporter` asks for OpenMetrics first and the classic format second, and the exporter answers with the type that Prometheus asks for. The graded lab gives you a page that fails and asks you to make it valid OpenMetrics.

<!-- astrona:playground -->
