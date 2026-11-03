# Overview: Time Series, Samples And Metric Types (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Prometheus and the example application `probe`, and then waits. There is no task, no `astrona submit` and no pass or fail. Run queries, change rules, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.
- Prometheus v3.5.5 in the namespace `starfleet`. It scrapes `probe` and itself every two seconds and evaluates rules every two seconds. It runs with `--web.enable-lifecycle`, so it reloads its configuration when it receives a POST request on `/-/reload`.
- The application `probe` with these metrics:

  | Metric | Type | Notes |
  | --- | --- | --- |
  | `lab_requests_total` | counter | Labels `service` and `status` |
  | `lab_queue_depth` | gauge | Constant value 3 |
  | `lab_last_success_timestamp_seconds` | gauge | Unix time of the last success |
  | `lab_request_duration_seconds` | histogram | Bounds 0.01, 0.05, 0.1 and `+Inf` |

- A traffic generator that sends four requests per second to `probe`. Every tenth request gets status 500.
- A pod `shuttle` with Python and `wget`, which you use to call the Prometheus API from inside the cluster.
- The ConfigMaps `prometheus-config` and `prometheus-rules`. The rule file `rules.yaml` holds no rule groups at the start.

## Helper

Paste this once in each new terminal. It sends a PromQL expression to the query API and prints the JSON answer on one line.

```sh
query_prometheus() {
  kubectl -n starfleet exec shuttle -- python -c 'import sys,urllib.parse,urllib.request; print(urllib.request.urlopen("http://prometheus:9090/api/v1/query?" + urllib.parse.urlencode({"query": sys.argv[1]})).read().decode())' "$1"
}
```

Use it like this: `query_prometheus 'lab_queue_depth'`. The result of an instant query has `data.result`, a list of series. Each entry has a `metric` object with the labels and a `value` pair of a timestamp and the sample value as a string. A range query such as `lab_requests_total[10s]` returns a `values` list instead.

## Exercise 1: read the identity of a series

Run `query_prometheus 'lab_requests_total'` and write down the full label set of each series. Count how many series the counter has and name the labels that came from the application and the labels that Prometheus added. Then run `query_prometheus '{__name__=~"lab_.*"}'` and count the series of each metric. The histogram has the most series. Explain why from the bucket bounds.

Next, ask for the label names and the values of `status`:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/labels
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/label/status/values
```

Check that the first answer contains `__name__` and that the second contains `200` and `500` only.

## Exercise 2: counters

Run `query_prometheus 'lab_requests_total'` twice with a pause of about ten seconds and compute the difference of the `200` series by hand. Divide it by the seconds between the two runs. Then run `query_prometheus 'rate(lab_requests_total[1m])'` and compare the result with your number. The two values are close but not identical, because `rate` extrapolates to the edges of its window.

Predict the answer of each of these queries before you run it:

- `sum(rate(lab_requests_total[1m]))`
- `sum by (status) (rate(lab_requests_total[1m]))`
- `increase(lab_requests_total[1m])`
- `rate(lab_requests_total[1s])`

For the last one, remember that a window needs at least two samples and that the scrape interval is two seconds. Explain the result.

## Exercise 3: gauges and the wrong function

Run `query_prometheus 'lab_queue_depth'` and `query_prometheus 'time() - lab_last_success_timestamp_seconds'`. Read the second answer as the age in seconds of the last successful request. Then run `query_prometheus 'rate(lab_queue_depth[1m])'`. The value is 0 because the gauge is constant. Explain why the same query on a gauge that goes up and down would give a misleading number.

## Exercise 4: histograms

Run the three queries below. Compare the `+Inf` bucket with `_count`, calculate the average duration from `_sum` and `_count`, and estimate the 95th percentile.

```sh
query_prometheus 'lab_request_duration_seconds_bucket'
query_prometheus 'rate(lab_request_duration_seconds_sum[1m]) / rate(lab_request_duration_seconds_count[1m])'
query_prometheus 'histogram_quantile(0.95, sum by (le) (rate(lab_request_duration_seconds_bucket[1m])))'
```

Now break the last query on purpose. Remove `rate(...)` and use the raw buckets, and then replace `sum by (le)` with `sum`. Describe how each result differs, and why the second variant returns no result.

Ask the server for the type of each metric:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/metadata?metric=lab_request_duration_seconds'
```

## Exercise 5: recording rules

Save a ConfigMap named `prometheus-rules` in the namespace `starfleet` with the key `rules.yaml` and one group of recording rules of your own design. For example, record the request rate per status under the name `status:lab_requests:rate1m`, then the median request duration. Save it as `rules-practice.yaml`, then apply it and restart Prometheus:

```sh
kubectl apply -f rules-practice.yaml
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

Wait about a minute and query the recorded names. Check the health of each rule in the answer of `http://prometheus:9090/api/v1/rules`. Break a rule on purpose, for example with a missing bracket, and read the `lastError` or the log of the Prometheus pod to see what a faulty rule file looks like.

## Questions to answer when you finish

- Which labels identify one series of `lab_requests_total`, and which of them did the application define?
- Why does the counter need `rate`, and why must `rate` come before `sum`?
- Why does `histogram_quantile` need the label `le`?
- What would a summary change for the percentile of two instances?

Run `astrona destroy ats-048-playground-040-01` when you are done.
