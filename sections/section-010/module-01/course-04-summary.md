---
draft: true
exam_objectives:
- System Architecture
---
# Summary

Prometheus collects metrics with a pull model. An application or an exporter exposes its current values as text on an HTTP endpoint, and the scrape manager of the Prometheus server fetches that text at every scrape interval. The server adds the labels `job` and `instance`, and it records the series `up` and the `scrape_*` series that describe each scrape. A value of 1 for `up` shows that a scrape worked. It says nothing about the health of the application itself.

The time series database stores each sample in two places at first: the head block in memory and the write-ahead log on disk. About every two hours the older part of the head becomes an immutable block, small blocks are compacted into larger ones, and retention deletes whole blocks that are older than the limit. Because the database is local to one server, its history is limited by the disk and the retention setting.

The PromQL engine reads this data. An instant vector selector returns the latest sample of each matching series, a range vector gives the samples of a time window, and functions such as `rate` turn counter totals into per-second values. The HTTP API returns every result in a JSON envelope with a `status` field and a `data` object. The endpoint for instant queries returns a vector, and the endpoint for range queries returns a matrix. A stale marker removes a vanished series from query results.

A recording rule runs a PromQL expression on a schedule and stores the result as a new series. The rule manager evaluates the rules of a group in order at the group's interval. Rule files are listed under `rule_files` in the configuration, and the server reads them only at start and on reload. The naming convention `level:metric:operations` keeps recorded series recognisable. A recording rule has no history before its first evaluation, and it cannot restore samples that a scrape missed.

Four facts are worth remembering. The scrape manager, the time series database, the PromQL engine, the rule manager and the web server are the parts of the server that make up this pipeline. A value of 0 for `up` can come from a refused connection, a timeout, a bad status code or a parse error. The default retention time is 15 days, and the default lookback for an instant query is five minutes. A changed rule file needs a reload or a restart before the server evaluates it.

<!-- astrona:playground:destroy -->
