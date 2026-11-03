---
draft: true
exam_objectives:
- Understanding Prometheus Limitations
---
# Retention Flags And Query Limits

A Prometheus server keeps adding blocks to its disk. If nothing removes old data, the disk fills and the server stops ingesting. Prometheus solves this with retention: the server deletes old blocks by rules that you set with command-line flags. A second problem is that one expensive query can use the memory of the whole server. Prometheus solves this with query limits, also set by flags. This lesson explains the four flags that matter, how the server applies them and how to check what a running server really uses.

## Flags are read once, at start

Prometheus has two places for settings. The configuration file (`prometheus.yaml`) holds scrape jobs, rules and similar settings, and the server can reload it while it runs. Command-line flags hold the settings of the process itself: the storage path, the retention, the query limits and the web options. The server reads flags only when it starts. A change to a flag takes effect only after the process restarts. In Kubernetes, the flags are the `args` of the `prometheus` container, so a change to the Deployment starts a new pod, which then runs with the new flags.

This difference explains a frequent mistake: a learner edits the flag in a file, the running server does not change, and the learner assumes the setting is active. The only trustworthy answer is the status API, which reports the flags of the running process.

<!-- astrona:playground:renew -->

Ask the server for its flags:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/status/flags
```

The result is a JSON object whose `data` field maps each flag name to its value as text. Find these keys: `storage.tsdb.retention.time`, `storage.tsdb.retention.size`, `query.timeout` and `query.max-samples`. On a server that you have not tuned, the time retention is `15d`, no size limit is set, the query timeout is two minutes and the sample limit is 50000000. Read the real text in your playground and keep it for comparison.

## Time retention

The flag `--storage.tsdb.retention.time` sets how long the server keeps data. The value is a duration such as `6h`, `15d` or `1y`. If you set neither the time flag nor the size flag, the server uses 15 days. The server checks the blocks on disk, and it deletes a block when the whole block is older than the limit.

The last words matter. Blocks cover time ranges, and a block is removed only when its newest sample is outside the retention window. A block that covers 10:00 to 12:00 stays until 12:00 is older than the limit. The data on disk is therefore somewhat older than the exact limit. The cleanup also runs in the background and can take up to two hours to remove a block that is already expired. Never treat the retention time as an exact cut-off in your reasoning about what data exists.

## Size retention

The flag `--storage.tsdb.retention.size` sets a maximum size for the persistent data, for example `500MB` or `100GB`. The default is 0, which turns the limit off. When the size is above the limit, the server deletes the oldest blocks first until the size is below the limit again.

Two facts help you to read a size limit correctly. First, the size that the server compares includes the WAL and the memory-mapped chunk files, but only blocks can be deleted to get under the limit. If the WAL alone is larger than the limit, deleting every block does not help, and the server cannot reach the target. Second, the server removes whole blocks, so the real size moves around the limit. Many operators set the size flag to about 80 to 90 percent of the disk, so that the head block, the WAL and the compaction work have room.

If you set both flags, the first limit that is reached removes data. A server with `--storage.tsdb.retention.time=6h` and `--storage.tsdb.retention.size=500MB` keeps at most 6 hours of data, and also never keeps more than about 500MB, even when the data is younger than 6 hours.

## Plan the size on disk

The Prometheus documentation gives a simple formula for the disk space you need:

```text
needed_disk_space = retention_time_seconds * ingested_samples_per_second * bytes_per_sample
```

Prometheus stores on average one to two bytes per sample, because the chunk format compresses well. You can measure the rate of ingested samples on your own server with a query. The two parts of the formula are the retention time and the ingestion rate, so doubling either one doubles the disk use. The number of series does not appear directly in the formula, but it sets the ingestion rate: more series means more samples per second.

Try the rate on the playground server:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=rate(prometheus_tsdb_head_samples_appended_total%5B1m%5D)'
```

The value is the number of samples per second that the server appended in the last minute. Multiply it by a retention time in seconds and by two bytes to get a rough upper bound for the disk. The server also exports `prometheus_tsdb_storage_blocks_bytes`, the size of the blocks on disk, and `prometheus_tsdb_retention_limit_bytes`, which shows the configured size limit.

## Query limits

Retention protects the disk. Two other flags protect the memory and the processor from queries:

- `--query.timeout` sets the longest time one query may run. The default is two minutes. A query that runs longer is stopped and returns an error.
- `--query.max-samples` sets the maximum number of samples that one query may hold in memory at the same time. The default is 50000000. A query that would pass the limit fails with an error, and the server stays healthy.

These flags limit the cost of a single query. They do not limit how many series the server ingests, and they do not limit how many queries run in parallel. A dashboard that sends many heavy queries can still use a lot of memory, even when each query is below the limits. Another flag, `--query.max-concurrency`, limits how many queries run at the same time, and its default is 20.

When a query fails because of the sample limit, the error message names the limit. A common reaction is to raise the limit. A better first step is to change the query: select fewer series with label matchers, or use a shorter time range, or a recording rule that stores a pre-computed result.

## How the flags are set

In Kubernetes, you add each flag as one more string in the `args` list of the `prometheus` container. You must keep the existing arguments, because `--config.file` and `--storage.tsdb.path` are needed to start, and `--web.enable-lifecycle` is needed for the reload endpoint. The flags that this lesson covers are written like this:

- `--storage.tsdb.retention.time=6h`
- `--storage.tsdb.retention.size=500MB`
- `--query.timeout=30s`
- `--query.max-samples=10000000`

After the Deployment changes, Kubernetes starts a new pod. Wait for the rollout to finish, then ask the status API again to confirm that the values are active. In the playground, the data directory is an `emptyDir` volume, so the new pod starts with an empty database. The retention flags do not cause this loss; the volume type does.

Check how the server reports its retention in its own metrics:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=prometheus_tsdb_retention_limit_bytes'
```

With no size limit, the value is 0. After you set a size limit, this metric holds the limit in bytes. This is a second source of evidence besides the flags API.

## Summing up

You now know that retention works on whole blocks, that the time flag and the size flag both delete the oldest blocks, that the first limit reached wins, and that the query flags protect memory from single queries. You also know that only the status API proves what a running server uses. The open question is why a single server has these limits at all, and what happens when one server is not enough. That is the topic of the next lesson.

## Common pitfalls

> [!WARNING]
> - Do not assume a flag is active because it is in a file. Read `/api/v1/status/flags` from the running server.
> - Do not replace the whole `args` list when you add flags. The server needs `--config.file` and `--storage.tsdb.path`, and the reload endpoint needs `--web.enable-lifecycle`.
> - A size limit that is too close to the disk size leaves no room for the WAL and compaction. Choose a limit clearly below the disk size.
> - Raising `--query.max-samples` hides a query that is too wide. Fix the query first.
> - Retention does not reduce the number of series in the head block. Only fewer scraped series do that.
