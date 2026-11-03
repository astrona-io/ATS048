---
draft: true
exam_objectives:
- System Architecture
---
# Overview: Follow Samples Through The Pipeline (Playground)

This is a playground, not a lab. It starts a cluster with a running Prometheus server, one instrumented application and a traffic generator, and then waits for you. There is no task to submit and no pass or fail. Explore, break things, and start again with a new playground when you want a clean state.

## What is running

All workloads are in the namespace `starfleet`.

| Object | What it does |
| --- | --- |
| Deployment `probe` | An application that serves `/work` and exposes request counters, a gauge and a histogram on `/metrics` |
| Deployment `traffic` | Sends requests to `probe`; about one in ten fails with status 500 |
| Deployment `prometheus` | Prometheus v3.5.5, scraping `probe` and itself every two seconds |
| Pod `shuttle` | A pod with the `wget` command, used to call HTTP endpoints inside the cluster |
| ConfigMaps `prometheus-config` and `prometheus-rules` | The configuration file and the rule file the server loads |

The rule file starts with `groups: []`, so no rule is evaluated yet. Another namespace, `outpost`, holds a pod named `drifter` that you can ignore in this module.

## Connect to the cluster

Select the private cluster of this playground and confirm the context:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-048-playground-010-01)"
kubectl config current-context
```

The context name must contain `ats-048-playground-010-01`. Keep this terminal for all exercises. The commands below use the `shuttle` pod to reach Prometheus. Set a helper so that you type the address once:

```sh
prom_get() {
  kubectl -n starfleet exec shuttle -- wget -qO- "http://prometheus:9090$1"
}
```

Use it as `prom_get /api/v1/targets`. Quote the whole argument if it contains a question mark.

## Exercise 1: Read the exposed text

Fetch the metrics text from the application directly and identify the type of each metric from its `# TYPE` line:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://probe:8080/metrics
```

Answer these questions in your own notes. Which metrics are counters, which are gauges and which belong to the histogram? Which labels does the counter carry? Fetch the text twice, a few seconds apart, and compare the counter values. They must not decrease.

## Exercise 2: Check scrape health

List the targets and read the fields `health`, `scrapeUrl` and `lastScrapeDuration`:

```sh
prom_get /api/v1/targets
```

Then run the queries `up`, `scrape_duration_seconds` and `scrape_samples_scraped` through `/api/v1/query?query=...`. Find the sample count that `probe` returns on every scrape. Compare it with the number of lines in the metrics text that are not comments.

## Exercise 3: Instant queries and range queries

Run an instant query for the raw counters, and one for the per-second rate:

```sh
prom_get '/api/v1/query?query=lab_requests_total'
prom_get '/api/v1/query?query=sum%20by%20(status)%20(rate(lab_requests_total%5B1m%5D))'
```

The second command uses percent encoding for the spaces and the square brackets. The ratio of the 500 rate to the total rate should be close to 0.1, but not exact, because the traffic generator is not perfectly regular. Then ask for a range query. It needs `start`, `end` and `step` parameters in Unix seconds, which you can compute with `date +%s` on your machine. Read the `resultType`, which must be `matrix`.

## Exercise 4: Break a query on purpose

Send three bad queries and read the `errorType` and `error` fields of each answer: a missing closing bracket, an unknown function name and a range vector without a function, such as `lab_requests_total[1m]` sent to the instant endpoint. Notice which of them is a parse error and which is a type error that is only found at evaluation.

## Exercise 5: Look at the storage settings

Read the flags and the build information of the server:

```sh
prom_get /api/v1/status/flags
prom_get /api/v1/status/buildinfo
prom_get /api/v1/status/tsdb
```

Find the data directory and the retention time. The TSDB status shows the head block statistics, including the number of series and the highest-cardinality metric names. Which metric has the most series in the head?

## Exercise 6: Write a recording rule

Edit the ConfigMap `prometheus-rules` so that it holds one group with the rule `job:lab_queue_depth:max`, which records `max by (job) (lab_queue_depth)`. Use `kubectl edit configmap prometheus-rules -n starfleet` or save a YAML file and apply it. Restart the server with:

```sh
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

Wait for a minute, then check `/api/v1/rules` for a `health` of `ok` and query the recorded name. Now make the expression invalid on purpose, restart, and read what the server logs with `kubectl -n starfleet logs deployment/prometheus`. A broken rule file prevents the server from starting normally, so you must fix the ConfigMap and restart again.

## Exercise 7: Use the reload endpoint

The server runs with the lifecycle API enabled. Change a rule, wait about a minute for Kubernetes to update the mounted file, and send a reload request instead of a restart:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- --post-data='' http://prometheus:9090/-/reload
```

Check `/api/v1/rules` to confirm that the change took effect and that the history of the earlier recorded series survived, since a reload does not restart the process or empty the database.

## Clean up

Nothing needs cleaning up inside the cluster. When you are done, remove the playground or let it expire. Starting a new playground gives you the original empty rule file and a fresh database again.
