---
draft: true
exam_objectives:
- Understanding Prometheus Limitations
---
# Summary

Prometheus stores its data in a local time series database that belongs to one server process. A sample first goes into the head block in memory, and the write-ahead log records the append so the head block can be rebuilt after a crash. About every two hours, the server writes the older part of the head block to an immutable block on disk, and a background process merges small blocks into larger ones.

Retention decides when blocks are deleted. The time flag removes blocks that lie completely outside the window, the size flag removes the oldest blocks when the persistent data is too large, and the first limit that is reached wins. Because whole blocks are removed in the background, data stays a little longer than the exact limit. Flags are read only at start, so the status API of the running server is the proof of what is active. The query timeout and the query sample limit protect the server from a single expensive query, but they do not limit how many series are ingested.

Memory use follows the number of active series, which is the cardinality. Every unique combination of a metric name and label values is one series, and a label with an unbounded set of values creates an unbounded number of series. Disk use follows the retention time, the sample rate and about one to two bytes per sample.

Prometheus has no clustering and no replication. Capacity grows by giving one server more resources or by splitting the targets among independent servers. High availability means two identical servers that scrape the same targets, each with its own data and a replica label, and Alertmanager merges their duplicate alerts. The pair gives protection against the loss of one server. It does not give more capacity, one shared database or durable long-term history.

<!-- astrona:playground:destroy -->
