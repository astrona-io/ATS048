# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-040/capstone/labs/lab-01
```

Submit once before you change anything. All four checks fail, because the rules file is empty.

## Step 1: Choose a function for each metric type

Each of the four rules needs a different treatment. The metric type decides the function.

- A counter only grows, so its raw value is not useful. `rate()` turns it into a per-second increase over a window. `rate` handles counter resets, which happen when the application restarts.
- A histogram is a set of cumulative counters, one per bucket bound. `histogram_quantile` estimates a percentile from them. The buckets must be turned into rates first, and they must keep the label `le`, because the function needs the bounds.
- The counter `lab_http_requests_total` in this lab never changes. The task asks for its sum, not for a rate. A rate of a constant counter is zero.

## Step 2: Choose the labels each rule keeps

An aggregation operator removes labels. `sum by (job)` keeps `job`. `sum by (path)` keeps `path` and removes `request_id`, which has 100 values for each path. `sum` without a clause removes all labels and returns one series. `sum by (le)` keeps `le`, and `histogram_quantile` then returns a result without labels.

A recording rule stores the result under the name in `record`. The stored series has the labels of the result plus the name. A rule that keeps `request_id` would store 300 series instead of 3. That is the cost of a high-cardinality label that nobody needs.

## Step 3: Select with a regular expression matcher

The failed requests are the series whose `status` starts with 5. The matcher `status=~"5.."` selects the values that match the regular expression, which is anchored at both ends: a 5 followed by two characters. The matcher `status="5.."` would compare the literal text. A selector with only `=~` and `!~` matchers is valid as long as one matcher cannot match the empty string, and the metric name provides that here.

## Step 4: Write the rules

Save this as `prometheus-rules.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
  namespace: starfleet
data:
  rules.yaml: |
    groups:
    - name: lab_capstone
      interval: 5s
      rules:
      - record: job:lab_requests:rate1m
        expr: sum by (job) (rate(lab_requests_total[1m]))
      - record: lab:requests_failed:rate1m
        expr: sum(rate(lab_requests_total{status=~"5.."}[1m]))
      - record: path:lab_http_requests:sum
        expr: sum by (path) (lab_http_requests_total)
      - record: lab:request_duration_seconds:p90
        expr: histogram_quantile(0.9, sum by (le) (rate(lab_request_duration_seconds_bucket[1m])))
```

Apply it and restart Prometheus:

```sh
kubectl apply -f prometheus-rules.yaml
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

The rules are evaluated every 5 seconds in this group. Wait about a minute so that the one-minute rates have samples in their window.

## Step 5: Check the result

Query the new series:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=job:lab_requests:rate1m'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=path:lab_http_requests:sum'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/rules'
```

The first answer has one series whose labels are `__name__` and `job`. The second has three series, one for each path, each with the value 5050, the sum of 1 to 100. The rules answer lists the group `lab_capstone` with four rules, each with the health `ok`.

## Step 6: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-040/capstone/labs/lab-01 --keep
```

Four checks must pass.

## What each check proved

- `rules-healthy` required all four names as recording rules with health `ok`.
- `request-rates` proved that the aggregation removed the other labels and that the regular expression matcher selected the failing status.
- `path-sum` proved that `request_id` is aggregated away and that each path sums to 5050.
- `latency-p90` required a value between 0 and 0.1 seconds, the highest finite bucket bound of the histogram.

## If a check fails

- If a rule is missing from the API, check that the file was loaded: an empty `groups` list means Prometheus did not read the new content.
- If a rule shows health `err`, the `lastError` field names the problem, such as a misspelled function.
- If `path-sum` fails with 300 series, the aggregation clause is missing or lists `request_id`.
