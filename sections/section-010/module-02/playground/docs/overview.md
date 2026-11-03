---
draft: true
exam_objectives:
- System Architecture
---
# Overview: Follow An Alert From Rule To Webhook (Playground)

This is a playground, not a lab. It starts a cluster with Prometheus, Alertmanager, one instrumented application and a traffic generator, and then waits for you. There is no task to submit and no pass or fail. Change things, break them and start a new playground when you want a clean state.

## What is running

All workloads are in the namespace `starfleet`.

| Object | What it does |
| --- | --- |
| Deployment `probe` | An application that serves `/work` and `/metrics`, and stores the webhook bodies it receives at `/hooks` |
| Deployment `traffic` | Sends requests to `probe`; about one in ten fails with status 500 |
| Deployment `prometheus` | Prometheus v3.5.5 with the ConfigMaps `prometheus-config` and `prometheus-rules` |
| Deployment `alertmanager` | Alertmanager, listening on port 9093 through the Service `alertmanager`, with one webhook receiver |
| Pod `shuttle` | A pod with the `wget` command, used to call HTTP endpoints in the cluster |

Prometheus and Alertmanager are separate processes. Check at the start whether Prometheus already knows Alertmanager. If both lists in the answer are empty, the first exercises connect them.

## Connect to the cluster

Select the private cluster of this playground and confirm the context:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-048-playground-010-02)"
kubectl config current-context
```

The context name must contain `ats-048-playground-010-02`. Define two helpers, one for each system:

```sh
prom_get() {
  kubectl -n starfleet exec shuttle -- wget -qO- "http://prometheus:9090$1"
}
alert_get() {
  kubectl -n starfleet exec shuttle -- wget -qO- "http://alertmanager:9093$1"
}
```

## Exercise 1: Check the connection

Ask both systems what they know about each other:

```sh
prom_get /api/v1/alertmanagers
alert_get /api/v2/status
```

Read the lists `activeAlertmanagers` and `droppedAlertmanagers`. In the Alertmanager status, find the route, the `group_by` list, the two timers and the receiver `webhook`. Write down which address the webhook receiver sends to.

## Exercise 2: Write an alerting rule and watch the states

Add a group to the ConfigMap `prometheus-rules` with an alerting rule that is true whenever more than five percent of requests fail. Use the counter `lab_requests_total` with the label `status="500"`, a one-minute `rate`, a `for` of 10 seconds and the label `severity: page`. Save the file, apply it, and restart the server:

```sh
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

Wait about a minute for the rate to have data. Then call `prom_get /api/v1/alerts` several times in a row. Watch the `state` field change from `pending` to `firing`, and read `activeAt`. Compare the time difference with your `for` value.

## Exercise 3: Connect Prometheus to Alertmanager

If the `alerting` section is missing, add an `alertmanagers` list with a `static_configs` target for the Service `alertmanager` at port 9093 to the ConfigMap `prometheus-config`. Keep the scrape jobs. Apply it, restart the server and check `prom_get /api/v1/alertmanagers` again. The `url` of the active entry must contain the port. Then look at what Alertmanager received:

```sh
alert_get /api/v2/alerts
```

Find the labels `alertname` and `severity` in the answer, and notice which labels the expression kept.

## Exercise 4: See the webhook delivery

The receiver of Alertmanager is the `probe` application. It keeps every notification body that it receives. Read them:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://probe:8080/hooks
```

The answer is a JSON list. Each body has the fields `status`, `alerts`, `groupLabels` and `receiver`. Check that `groupLabels` contains the label that `group_by` names. Wait longer than the `group_interval` and call it again. Count the notifications and relate the count to the timers you read in exercise 1.

## Exercise 5: Break the chain at each step

Do one break at a time, restore it, and write down what you see in Prometheus, in Alertmanager and at the webhook:

- Change the port of the Alertmanager address in the Prometheus configuration to a wrong number. Which system still shows the alert?
- Misspell the metric name in the rule expression. Is the rule `health` still `ok`? What is the alert state?
- Raise the `for` duration to five minutes. How long does the alert stay `pending`?

After each change, restart the Prometheus Deployment and wait for it to be ready.

## Exercise 6: Look at the extensions

Read the full effective configuration and look for `remote_write`, `remote_read` and `alerting`:

```sh
prom_get /api/v1/status/config
```

Then fetch the federation endpoint for the series of the `probe` job, and compare the output with a normal instant query for the same selector:

```sh
prom_get '/federate?match[]=up'
prom_get '/api/v1/query?query=up'
```

The federation answer is plain exposition text with labels, and the query answer is a JSON document. Think about which one a second Prometheus server could scrape.

## Clean up

Nothing needs cleaning up inside the cluster. When you are done, remove the playground or let it expire. A new playground has the original configuration again.
