---
draft: true
exam_objectives:
- Understanding Prometheus Limitations
---
# What Prometheus Is Not For

Prometheus answers one kind of question very well: how a numeric measurement changes over time, such as the request rate, the error ratio or the memory in use. Teams often expect more from it. They try to find one failed request, to count money to the cent, to see data from a machine it cannot reach or to keep ten years of history. Prometheus was not designed for these jobs, and the design choices that make it good at its own job explain why.

This module names the limits and gives the reason for each one. It covers the difference between metrics and logs, traces and events, why a counter is not an accounting ledger, how the pull model and the staleness rules produce gaps, why a rate is an estimate, how long-term storage is added outside the server and how far you can trust the delivery of alerts. It ends with the settings that protect the server from a target that sends too much data.

## Learning goals

- Say which kinds of data belong in metrics and which belong in logs, traces or an event store.
- Explain why a counter and its rate are estimates, and when that is not good enough.
- Describe the pull model, its reach limits, staleness and the gaps that failed scrapes leave.
- Explain how remote write adds long-term storage, and what it does not change.
- Explain the delivery path of alerts and its failure points.
- Use `sample_limit` and related limits to stop a target that sends too many series.

## What you should know first

You should know that Prometheus scrapes the `/metrics` page of its targets and stores numeric samples, and that a time series is a unique combination of a metric name and labels. The module explains the other terms. The playground has Prometheus v3.5.5 in the namespace `starfleet`, the `probe` application with a traffic generator, a `shuttle` pod with `wget`, and an application named `crowded` that exposes 200 series with a `ticket_id` label.

## Reading order

The first lesson separates metrics from logs, traces and events, and explains the precision limits of counters and rates. The second lesson covers the pull model, staleness, long-term storage and the path that an alert takes. The third lesson covers the limits that protect the server, and a graded task follows it. The summary closes the module.

<!-- astrona:playground -->
