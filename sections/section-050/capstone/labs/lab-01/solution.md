# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-050/capstone/labs/lab-01
```

Submit once before you change anything. All four checks fail, because the page does not parse.

## Step 1: Read the parse error

A page that has one invalid line fails as a whole. Prometheus keeps no sample of that scrape and the target is `down`. The reason is in the targets API:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/targets?state=active'
```

Find the target with the job `exporter`. Its `lastError` names the first line that the parser rejects. The parser stops at the first error, so there may be more faults on later lines.

## Step 2: Find the three faults

Read the page and check each line against the format:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://exporter:8080/metrics
```

- The first sample has `queue=default`. A label value is always inside double quotes.
- The gauge sample is `lab_workers four`. A sample value must be a number.
- The histogram has the buckets 0.1, 0.5 and 1, but no bucket with the bound `+Inf`. The page still parses without it, because Prometheus does not check that a histogram is complete. The result is wrong later. The `+Inf` bucket holds all observations, so it must equal the `_count` value, 1040. Without it `histogram_quantile` returns `NaN`.

The first two faults make the scrape fail. The third makes a successful scrape deliver an unusable histogram, so the check for it comes after the page parses.

## Step 3: Write the corrected page

Bucket values are cumulative: the bucket with the bound 1 counts every observation up to 1, so the values never decrease from bucket to bucket.

Save this as `exporter-metrics.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: exporter-metrics
  namespace: starfleet
data:
  metrics.txt: |
    # HELP lab_jobs_processed_total Jobs processed by the worker, by result.
    # TYPE lab_jobs_processed_total counter
    lab_jobs_processed_total{queue="default",result="ok"} 1027
    lab_jobs_processed_total{queue="default",result="error"} 13
    # HELP lab_workers Number of running workers.
    # TYPE lab_workers gauge
    lab_workers 4
    # HELP lab_task_duration_seconds Task duration in seconds.
    # TYPE lab_task_duration_seconds histogram
    lab_task_duration_seconds_bucket{le="0.1"} 600
    lab_task_duration_seconds_bucket{le="0.5"} 900
    lab_task_duration_seconds_bucket{le="1"} 1000
    lab_task_duration_seconds_bucket{le="+Inf"} 1040
    lab_task_duration_seconds_sum 412.5
    lab_task_duration_seconds_count 1040
```

```sh
kubectl apply -f exporter-metrics.yaml
kubectl -n starfleet rollout restart deployment/exporter
kubectl -n starfleet rollout status deployment/exporter
```

A ConfigMap mounted as a volume reaches the pod with a delay. The restart avoids the wait.

## Step 4: Check the result

After the next scrape, query:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=up{job="exporter"}'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=histogram_quantile(0.9,lab_task_duration_seconds_bucket)'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/metadata?metric=lab_task_duration_seconds'
```

`up` is 1. The quantile is a number between 0.5 and 1, because the 90th percentile of 1040 observations is observation 936, and 900 observations are at or below 0.5 and 1000 are at or below 1. The metadata entry lists the type `histogram`.

## Step 5: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-050/capstone/labs/lab-01 --keep
```

Four checks must pass.

## What each check proved

- `exporter-scrape-ok` required `up` equal to 1. It fails while any line is invalid.
- `counter-and-gauge` required the exact series and values, which proves the quotes and the numeric value.
- `histogram-complete` required the `+Inf` bucket and the count to equal 1040 and a finite quantile.
- `histogram-types` read the metadata API for the three families and proves the `# TYPE` lines are in place.

## If a check fails

- If `up` stays 0, read `lastError` again. A second fault on a later line appears only after the first one is fixed.
- If the quantile check fails while the buckets exist, check that the `+Inf` bucket is written as `le="+Inf"` with quotes.
- If nothing changes, the pod still serves the old page. Restart the Deployment.
