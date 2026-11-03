---
draft: true
exam_objectives:
- Understanding Prometheus Limitations
---
# Guided Practice: Inspect Storage, Retention And Limits

This playground has a Prometheus v3.5.5 server in the namespace `starfleet`, an application `probe` that exposes metrics, a traffic generator that sends requests to the probe and a `shuttle` pod that has `wget`. Prometheus scrapes every two seconds. Nothing in this guide is graded. The aim is to look at the storage of a running server, read its flags and connect each number to the idea that explains it.

The scenario: the platform team will move this Prometheus server to a small node, and you must find out what it stores today and which limits protect it.

Use a host shell and select the private kubeconfig of this playground. A kubeconfig is a file that tells `kubectl` which cluster to use and how to authenticate.

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-048-playground-030-01)"
kubectl config current-context
```

The current context must be `kind-astro-ats-048-playground-030-01`. If it shows another name, stop and select the right kubeconfig before you continue.

## Step 1: Check that the server runs

List the pods in the namespace:

```sh
kubectl -n starfleet get pods
```

You should see `prometheus`, `probe`, `traffic` and `shuttle`. Ask Prometheus whether it is ready. The `/-/ready` endpoint answers with a short text when the server has finished loading its data and replaying the write-ahead log (WAL):

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/-/ready
```

## Step 2: Read the flags of the running process

Flags are read only when the process starts. The status API shows the values that the process uses now:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/status/flags
```

Find `storage.tsdb.retention.time`, `storage.tsdb.retention.size`, `query.timeout`, `query.max-samples` and `storage.tsdb.path`. Write down the four limit values. Then look at the arguments that the Deployment passes to the container:

```sh
kubectl -n starfleet get deployment prometheus -o jsonpath='{.spec.template.spec.containers[0].args}'
```

Compare the two lists. The Deployment sets only a few flags. Every flag that it does not set keeps its default value, and the flags API shows those defaults. Ask yourself which of the four limits is the default and what that means: how long does this server keep data, and is there any limit on disk size?

## Step 3: Look inside the TSDB

Ask for the number of series in the head block:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=prometheus_tsdb_head_series'
```

Now read the detailed statistics of the head block:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/status/tsdb
```

Look at `headStats` and `seriesCountByMetricName`. Which metric names own the most series? The probe exposes a counter with a `status` label, a gauge and a histogram. Explain to yourself why the histogram metric has more series than the counter. The answer is in the number of buckets: each bucket is its own series.

Check the blocks and the WAL with queries. Run each one separately:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=prometheus_tsdb_blocks_loaded'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=prometheus_tsdb_wal_segment_current'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=prometheus_tsdb_head_chunks'
```

A playground that started recently has not yet run for two hours, so the number of loaded blocks can be 0. All samples are still in the head block, protected by the WAL. If you leave the playground running for more than two hours, check the blocks again and compare.

## Step 4: Estimate the disk need

Use the formula that the retention lesson gave: retention time in seconds multiplied by samples per second multiplied by bytes per sample. Measure the sample rate:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=rate(prometheus_tsdb_head_samples_appended_total%5B1m%5D)'
```

Take the value, which is samples per second. With the default retention of 15 days, which is 1296000 seconds, and an upper estimate of two bytes per sample, calculate the disk space. Then calculate it again for a retention of 6 hours, which is 21600 seconds. The comparison shows why the retention time is the main lever for disk use when the ingestion rate stays the same.

Check what the server reports about its own limit:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=prometheus_tsdb_retention_limit_bytes'
```

## Step 5: Predict cardinality

The probe exposes the metric `lab_requests_total` with the label `service` and the label `status`. Before you run the next query, predict the result from the labels. The traffic generator sends requests with status 200 and status 500, and the application starts with a counter for each of the two codes.

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=count(lab_requests_total)'
```

Compare the answer with your prediction. Then think about adding a label `request_id` to this metric. The traffic generator sends about four requests per second. How many series would that label create in one hour? Each request would create a new series, so about 14400 new series per hour, and none of them would ever receive a second sample. This is the pattern that makes a server run out of memory.

## Step 6: Observe the effect of a restart (optional)

The data directory of this server is an `emptyDir` volume. Restart the Deployment and watch the effect on the head block:

```sh
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

Ask for `prometheus_tsdb_head_series` again and check the lowest timestamp of the data with this query:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=prometheus_tsdb_lowest_timestamp'
```

The new pod started with an empty volume, so the earliest sample is recent. This shows why a server that must keep its history needs a persistent volume, and why a restart in the playground always discards the data.

## What you should be able to explain

After the steps, check yourself with these questions. Where does a new sample live first, and what protects it? Which flag removes old blocks by age, and which by size, and what happens when both are set? Why does data stay a little longer than the retention time? Which flag would stop a query that runs for minutes? What would an HA pair need to be added to this setup, and what would it not fix?

## Common pitfalls

> [!WARNING]
> - Check that the context is the one of this playground before you restart or change anything.
> - A value in a Deployment file does not prove that the server uses it. Read the flags API from the running server.
> - Do not delete files in the data directory. Use the flags and the restart to change the behavior.
> - A result of 0 for loaded blocks on a new server is normal. The first block appears only after the head block covers about two hours.
