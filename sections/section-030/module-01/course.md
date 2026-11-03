---
draft: true
exam_objectives:
- Understanding Prometheus Limitations
---
# Prometheus Storage And Scale

Prometheus is built to be simple to run: one server process scrapes targets, stores the samples on its own local disk and answers queries from that disk. This design makes the server reliable and easy to operate, but it also sets hard limits. The server does not form a cluster, it does not copy its data to other servers, and its memory use grows with the number of time series it tracks.

This module explains where those limits come from and which settings control them. You will see how the time series database (TSDB) holds recent samples in memory and in a write-ahead log, how it turns them into blocks on disk, and how retention flags decide when old blocks are deleted. You will also learn what cardinality costs and why high availability for Prometheus means running two independent servers.

## Learning goals

- Describe the head block, the write-ahead log (WAL), blocks and compaction, and say which part of the server owns each.
- Set time-based and size-based retention, and explain why data can stay longer than the limit.
- Use query timeout and query sample limits to keep one expensive query from harming the server.
- Explain why Prometheus has no clustering, and what a pair of identical servers gives you and what it does not.
- Relate the number of active series (cardinality) to memory, disk and query cost.

## What you should know first

You should know that Prometheus scrapes the `/metrics` page of each target on a fixed interval and stores each value as a sample with a timestamp. You should also know that a time series is one unique combination of a metric name and label values. The module explains every other term when it first appears.

The playground for this module runs Prometheus v3.5.5 in the `starfleet` namespace, scraping the `probe` application. A `shuttle` pod gives you `wget` so you can call the Prometheus HTTP API from inside the cluster.

## Reading order

The first lesson follows a sample from the scrape to the disk: head block, WAL, blocks and compaction. The second lesson covers the retention flags and the query limits, and a graded task follows it. The third lesson covers the single-node design, the cost of cardinality and high availability with a pair of servers. The summary closes the module.

<!-- astrona:playground -->
