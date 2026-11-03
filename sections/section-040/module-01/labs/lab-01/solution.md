# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-040/module-01/labs/lab-01
```

Submit once before you change anything. All four checks fail, because no rule exists.

## Step 1: Read the metric types from the server

Prometheus keeps the type that the application declares in the `# TYPE` line. The metadata API returns it. The type tells you which functions make sense:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/metadata?metric=lab_requests_total'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/metadata?metric=lab_queue_depth'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/metadata?metric=lab_request_duration_seconds'
```

The types are `counter`, `gauge` and `histogram`. Prometheus does not enforce that you use the right function, so the types are your guide.

## Step 2: Pick the function for each type

A counter only increases, and resets to zero when the process restarts. Its raw value has little meaning. The function `rate` takes the samples in a range, handles resets, and returns the average increase per second. `rate(lab_requests_total[1m])` returns one value for every label set, so there is one series for `status="200"` and one for `status="500"`. `sum by (status)` adds series with the same `status` and drops all other labels, such as `service` and `job`.

A histogram is a group of counters. Each `_bucket` series counts the observations that are less than or equal to the bucket bound in its `le` label. To compute a percentile, first take the `rate` of the buckets, so that the result reflects the last minute and not the total since start. Then sum by `le`, which keeps the bucket structure but removes the other labels. Last, `histogram_quantile(0.95, ...)` estimates the 95th percentile by interpolating inside the bucket where the 95th percent falls. The result is an estimate whose accuracy depends on the bucket bounds.

A gauge is a value that can go up and down, such as a queue depth. Its current sample is already meaningful, so you aggregate it directly. `rate` on a gauge is wrong, because a decrease is not a counter reset. `max(lab_queue_depth)` returns the highest value over all series.

## Step 3: Write the rules

Save this as `rules-types.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
  namespace: starfleet
data:
  rules.yaml: |
    groups:
    - name: lab_types
      interval: 5s
      rules:
      - record: status:lab_requests:rate1m
        expr: sum by (status) (rate(lab_requests_total[1m]))
      - record: lab:request_duration_seconds:p95
        expr: histogram_quantile(0.95, sum by (le) (rate(lab_request_duration_seconds_bucket[1m])))
      - record: lab:queue_depth:max
        expr: max(lab_queue_depth)
```

The names follow the convention `level:metric:operations`. The part before the first colon says which labels the series keeps, the middle part is the metric, and the last part says which operations were applied.

Apply the file and restart Prometheus so that it loads it:

```sh
kubectl apply -f rules-types.yaml
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

## Step 4: Check the three series

Wait about a minute, because a one-minute `rate` needs enough samples in its window. Then query each recorded name:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=status:lab_requests:rate1m'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=lab:request_duration_seconds:p95'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=lab:queue_depth:max'
```

The first answer has two series, one with `status` set to `200` and one set to `500`. The second has one series with no labels besides `__name__`, and a value in seconds. The third has the value 3, because the application reports a constant queue depth.

## Step 5: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-040/module-01/labs/lab-01 --keep
```

Four checks must pass.

## What each check proved

- `counter-rate-by-status` required exactly the status values `200` and `500`, positive values and no other label. A raw `lab_requests_total` copy would keep a huge cumulative value and the `service` label, and fails.
- `histogram-quantile` required one label-free series with a value between 0 and 0.1 seconds. The largest finite bucket of the histogram is 0.1, so a valid estimate cannot be larger. A `sum` that forgot to keep `le` returns no result.
- `gauge-max` required the value 3. `rate` on a gauge returns about 0, which fails.
- `rules-healthy` required all three names to be loaded from a file under `/rules/` with the health `ok`.

## If a check fails

- If a recorded series is missing and the rule health is `ok`, wait one more evaluation interval.
- If the percentile query has no result, check that the inner `sum by (le)` keeps the `le` label. `histogram_quantile` needs it.
- If a rule shows health `err`, read its `lastError` in `/api/v1/rules`.
