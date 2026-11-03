# Overview: Label Design, Cardinality And Staleness (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Prometheus and two example applications, and then waits. There is no task, no `astrona submit` and no pass or fail. Run queries, change the applications, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.
- Prometheus v3.5.5 in the namespace `starfleet`. It scrapes three targets every two seconds: the job `probe` (the address `probe:8080`), the job `prometheus` (`localhost:9090`) and the job `crowded` (`crowded:8080`).
- The application `crowded`, which exposes the counter `lab_http_requests_total`. The label `path` has three values (`/orders`, `/cart` and `/search`) and the label `request_id` has 100 values for each path, so the metric has 300 series. Each series holds a constant value from 1 to 100.
- The application `probe` with the counter `lab_requests_total` (labels `service` and `status`), the histogram `lab_request_duration_seconds` and two gauges, and a traffic generator that calls it.
- A pod `shuttle` with Python and `wget` to call the Prometheus API from inside the cluster.
- The ConfigMaps `prometheus-config` and `prometheus-rules`. The rule file `rules.yaml` holds no rule groups at the start.

## Helper

Paste this once in each new terminal. It sends a PromQL expression to the query API and prints the JSON answer on one line.

```sh
query_prometheus() {
  kubectl -n starfleet exec shuttle -- python -c 'import sys,urllib.parse,urllib.request; print(urllib.request.urlopen("http://prometheus:9090/api/v1/query?" + urllib.parse.urlencode({"query": sys.argv[1]})).read().decode())' "$1"
}
```

The result of an instant query has `data.result`, a list of series. Each entry has a `metric` object with the labels and a `value` pair of a timestamp and the sample value as a string. An empty `result` list means that nothing matched.

## Exercise 1: matchers

Predict the number each query returns before you run it, then check it with `query_prometheus`.

- `count(lab_http_requests_total)`
- `count(lab_http_requests_total{path="/cart"})`
- `count(lab_http_requests_total{path=~"/orders|/cart"})`
- `count(lab_http_requests_total{path!~"/search"})`
- `count(lab_http_requests_total{path=~"/ord"})`
- `count(lab_http_requests_total{request_id="r0007"})`

Explain the result of the fifth query. Then try the selector `{job=~".*"}` and read the error that the API returns. Change it to `{job=~".+"}` and describe the difference.

## Exercise 2: aggregation

Compare these four queries. For each one, write down which labels the result keeps and how many series it returns.

- `sum(lab_http_requests_total)`
- `sum by (path) (lab_http_requests_total)`
- `sum without (request_id) (lab_http_requests_total)`
- `count by (path) (lab_http_requests_total)`

The third query keeps `job` and `instance`, and the second does not. Explain why. Check that the sum for each path is 5050.

## Exercise 3: measure cardinality

Run the commands below. Find the number of series of `lab_http_requests_total`, the number of series in the head block and the metrics that Prometheus ranks first in its own status report.

```sh
query_prometheus 'count by (__name__) ({__name__=~".+"})'
query_prometheus 'prometheus_tsdb_head_series'
query_prometheus 'scrape_samples_scraped'
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/status/tsdb
```

Answer these questions: how many series would you have if you removed `request_id` from the counter, and how many would you have if you added a label `method` with four values that occur for every path and request identifier?

## Exercise 4: a recording rule for an aggregation

Save a ConfigMap named `prometheus-rules` in the namespace `starfleet` with the key `rules.yaml` and one group with a rule that records `sum by (path) (lab_http_requests_total)` under the name `path:lab_http_requests_total:sum`. Add a second rule that records `count by (path) (lab_http_requests_total)` under `path:lab_http_requests_total:series`. Save it as `rules-practice.yaml`, then apply it and restart Prometheus:

```sh
kubectl apply -f rules-practice.yaml
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

Wait about 20 seconds. Query both recorded names and check the values 5050 and 100. Then look at `prometheus_tsdb_head_series` again. The raw 300 series still exist, and the recorded series add three more for each rule.

## Exercise 5: staleness and series churn

First scale `crowded` to zero pods and watch the series end:

```sh
kubectl -n starfleet scale deployment/crowded --replicas=0
query_prometheus 'count(lab_http_requests_total)'
query_prometheus 'up{job="crowded"}'
```

The first answer is empty after a few seconds, and the second has the value 0. Explain why the first query is empty and not 0, and why the second returns a value. Scale the Deployment back to one pod and check that both queries return to normal.

The application can expose another metric instead. Its code is in the ConfigMap `crowded-code`, in the key `app.py`, and the first line sets `MODE = 'orders'`. Change the value to `'tickets'` and the application then exposes `lab_ticket_info` with a label `ticket_id` of 200 values, and no longer exposes `lab_http_requests_total`. Export the ConfigMap, edit the line with an editor, apply the file and restart the Deployment:

```sh
kubectl -n starfleet get configmap crowded-code -o yaml > crowded-code.yaml
kubectl apply -f crowded-code.yaml
kubectl -n starfleet rollout restart deployment/crowded
```

Edit `crowded-code.yaml` between the first and the second command. Wait for the new pod, then run `count(lab_http_requests_total)` and `count(lab_ticket_info)`. The first series ended, and the new one has 200 series. Run `rate(prometheus_tsdb_head_series_created_total[5m])` before and after the change and compare. Describe what a label with a changing value would do to a real server.

## Questions to answer when you finish

- Which labels identify one series of `lab_http_requests_total` and which of them add cardinality without use?
- What does a recording rule save, and what does it not save?
- Why does a stopped target return an empty answer and not 0?
- Which labels does Prometheus add to every series, and what does `up` show?

Run `astrona destroy ats-048-playground-040-02` when you are done.
