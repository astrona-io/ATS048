# Understanding Prometheus Limitations

This section covers what Prometheus does not do and why, and the settings that keep a server safe. It is part of the Prometheus Certified Associate (PCA) course ATS048. Each module has a landing page, three lessons, a summary and a playground. A graded lab follows the lesson that it practises, and a capstone lab combines both modules.

## Modules

- Prometheus Storage And Scale: the local time series database (head block, write-ahead log, blocks, compaction), retention by time and size, query limits, the single-node design, the cost of cardinality and high availability with a pair of servers.
- What Prometheus Is Not For: metrics compared with logs, traces and events, the estimate behind counters and rates, the reach of the pull model, staleness and gaps, long-term storage with remote write, the reliability of alert delivery and the per-job sample and label limits.

## Learning outcomes

After this section you can:

- Describe the head block, the WAL, blocks and compaction, and say what each protects.
- Set `--storage.tsdb.retention.time` and `--storage.tsdb.retention.size`, explain why data stays slightly longer than the limit and read the active flags from the status API.
- Set `--query.timeout` and `--query.max-samples` and explain what they limit and what they do not.
- Explain why Prometheus has no clustering, what a high availability pair gives and what it does not.
- Relate cardinality to memory use and find the metrics and labels that create the most series.
- Decide when a question needs logs, traces, events or a transactional store instead of Prometheus.
- Explain why `rate()` and `increase()` are estimates, and how the pull model, `up` and staleness create gaps.
- Explain remote write for long-term storage and the failure points of alert delivery.
- Protect a server with `sample_limit` and the label limits, and read the evidence of a rejected scrape.

## Labs and playgrounds

Module 1 and module 2 each have a graded lab right after the lesson that it practises, and each has a private playground without grading. The capstone lab sets retention flags and a sample limit on a crowded target. All labs and playgrounds are UNTESTED: they were written and checked statically and never booted.
