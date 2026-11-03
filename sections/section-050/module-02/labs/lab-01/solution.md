# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-050/module-02/labs/lab-01
```

Submit once before you change anything. All four checks fail because the target is down.

## Step 1: See which format is negotiated

A scrape request carries an `Accept` header. In the job `exporter`, the field `scrape_protocols` lists the formats that Prometheus accepts, in order of preference: first `OpenMetricsText1.0.0`, then the classic `PrometheusText0.0.4`. This example application reads the header and answers with the content type `application/openmetrics-text` when it finds it, and with `text/plain; version=0.0.4` otherwise. The parser Prometheus uses depends on the content type of the response, not on the file content.

Look at the failure reason:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/targets?state=active'
```

The `lastError` of the `exporter` target tells you that the data does not end with an `# EOF` line.

## Step 2: Know what OpenMetrics adds

OpenMetrics is a stricter format that grew out of the Prometheus text format. Three differences matter here.

- The page must end with the line `# EOF`. A page without it is treated as truncated, so a half-sent page can never be mistaken for a complete one.
- A counter is declared by its family name without a suffix: `# TYPE lab_jobs_failed counter`. The samples of the family carry the suffix `_total`: `lab_jobs_failed_total`. The page in this lab already follows that rule.
- A histogram needs a bucket with the bound `+Inf`. Its value must equal the `_count` value, because every observation is less than or equal to infinity.

Prometheus does not validate histogram completeness when it parses. The page parses, and the result is wrong later. If the `+Inf` bucket is missing, `histogram_quantile` returns `NaN`, because it needs the total count from the last bucket.

## Step 3: Correct the page

Save this as `exporter-metrics.yaml`. The ConfigMap name and the key stay the same:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: exporter-metrics
  namespace: starfleet
data:
  metrics.txt: |
    # HELP lab_jobs_failed Failed jobs by reason.
    # TYPE lab_jobs_failed counter
    lab_jobs_failed_total{reason="timeout"} 5
    lab_jobs_failed_total{reason="oom"} 2
    # HELP lab_job_duration_seconds Job duration in seconds.
    # TYPE lab_job_duration_seconds histogram
    lab_job_duration_seconds_bucket{le="0.1"} 600
    lab_job_duration_seconds_bucket{le="0.5"} 900
    lab_job_duration_seconds_bucket{le="1"} 1000
    lab_job_duration_seconds_bucket{le="+Inf"} 1040
    lab_job_duration_seconds_sum 412.5
    lab_job_duration_seconds_count 1040
    # EOF
```

The bucket values are cumulative: each bucket counts all observations up to its bound, so the numbers never decrease. Apply the file and restart the Deployment so that the new pod serves it:

```sh
kubectl apply -f exporter-metrics.yaml
kubectl -n starfleet rollout restart deployment/exporter
kubectl -n starfleet rollout status deployment/exporter
```

## Step 4: Check the result in Prometheus

Wait for the next scrape. Then query:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=up{job="exporter"}'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=lab_jobs_failed_total'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=histogram_quantile(0.9,lab_job_duration_seconds_bucket)'
```

`up` is 1 and the counter has two series. The quantile result is a number between 0.1 and 0.5, because 90 percent of 1040 observations is 936, which lies between the cumulative counts of the 0.5 and 1 buckets. The estimate falls inside the 0.5 to 1 bucket.

## Step 5: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-050/module-02/labs/lab-01 --keep
```

Four checks must pass.

## What each check proved

- `openmetrics-scrape-ok` required `up` equal to 1 under the negotiated OpenMetrics format, so the `# EOF` line is in place.
- `counter-total-series` required the two counter samples with their values.
- `histogram-complete` required that the `+Inf` bucket and the `_count` series both have the value 1040.
- `histogram-quantile-number` ran `histogram_quantile` and required a value between 0 and 1 second. With the `+Inf` bucket missing, the function returns `NaN` and the check fails.

## If a check fails

- If `up` stays 0, read `lastError` again. A blank line after `# EOF`, or any line after it, is also an error.
- If the quantile check fails while the buckets exist, check that the `+Inf` bucket is written with quotes, as `le="+Inf"`, and that it is the largest value.
- If the page looks right but nothing changed, the pod still serves the old page. Restart the Deployment.
