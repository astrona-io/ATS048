# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-010/module-02/labs/lab-01
```

Submit once before you change anything. All four checks fail, because Prometheus has no connection to Alertmanager and no rule exists. That is the expected starting state.

## Step 1: See that Alertmanager is not connected

Prometheus and Alertmanager are two separate processes. Prometheus evaluates alerting rules and sends the firing alerts over HTTP. Alertmanager does the grouping and notification. Prometheus only sends alerts to the addresses listed in the `alerting` section of its configuration. List what it knows now:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/alertmanagers
```

Both lists in the answer, `activeAlertmanagers` and `droppedAlertmanagers`, are empty.

## Step 2: Add the alerting section and the rule

The `alerting` section has a list `alertmanagers`. Each entry is a target group, written like a scrape target group, with `static_configs` and `targets`. Prometheus sends every alert to every Alertmanager in this list.

An alerting rule has the fields `alert` (the alert name), `expr` (the condition), `for` (how long the condition must stay true before the alert changes from pending to firing), `labels` and `annotations`. The expression returns a result only for the label sets where the condition is true. An empty result means no alert.

Save this as `prometheus-alerting.yaml`. It replaces both ConfigMaps in one file:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: starfleet
data:
  prometheus.yaml: |
    global:
      evaluation_interval: 2s
      scrape_interval: 2s
    alerting:
      alertmanagers:
      - static_configs:
        - targets:
          - alertmanager:9093
    rule_files:
    - /rules/*.yaml
    scrape_configs:
    - job_name: probe
      static_configs:
      - labels:
          team: starfleet
        targets:
        - probe:8080
    - job_name: prometheus
      static_configs:
      - targets:
        - localhost:9090
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
  namespace: starfleet
data:
  rules.yaml: |
    groups:
    - name: lab_alerts
      interval: 5s
      rules:
      - alert: LabHighErrorRatio
        expr: sum(rate(lab_requests_total{status="500"}[1m])) / sum(rate(lab_requests_total[1m])) > 0.05
        for: 10s
        labels:
          severity: page
        annotations:
          summary: More than five percent of probe requests fail
```

Apply it:

```sh
kubectl apply -f prometheus-alerting.yaml
```

## Step 3: Restart Prometheus

Prometheus reads its configuration and rule files at start and on reload. A new pod reads the current ConfigMaps, so restart the Deployment:

```sh
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

## Step 4: Follow the alert through its states

An alert moves through three states. It is inactive while the expression returns nothing. It is pending while the expression is true but the `for` duration has not passed. It is firing after the expression has been true for the whole `for` duration. Prometheus needs about a minute after the restart to collect enough samples for a one-minute `rate`.

Ask for the alerts that Prometheus holds:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/alerts
```

Each alert has a `state` field. Run the command again until `LabHighErrorRatio` shows `firing`. Then check that Prometheus now sees Alertmanager:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/alertmanagers
```

The `activeAlertmanagers` list has one entry whose `url` contains `alertmanager:9093`.

Finally, ask Alertmanager what it received. This is a different system than Prometheus, so it holds its own copy of the alert:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://alertmanager:9093/api/v2/alerts
```

The answer is a list with one alert. Its `labels` object has `alertname` and `severity`, and also the labels that the expression kept. Because the expression uses `sum(...)`, no `job` or `instance` label is left.

## Step 5: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-010/module-02/labs/lab-01 --keep
```

Four checks must pass.

## What each check proved

- `alertmanager-connected` read `/api/v1/alertmanagers` and required an active entry for port 9093. It proves that the configuration change was loaded, not only saved.
- `alert-rule-defined` read the rules API and required the alert name, type `alerting`, a duration of 10 seconds, the label `severity=page` and healthy evaluation.
- `alert-firing` read `/api/v1/alerts` and required the state `firing`. A rule with a wrong expression stays inactive and never fires.
- `alert-delivered` asked Alertmanager itself. A firing alert in Prometheus is not enough, because delivery needs the connection from step 2.

## If a check fails

- If `alert-firing` fails, run the alerts call. An empty list means the expression returns nothing; try it as a query in `/api/v1/query` to see why. A `pending` alert needs ten more seconds.
- If `alert-delivered` fails but `alert-firing` passes, the `alerting` section is missing or points to a wrong address. Check `activeAlertmanagers` and `droppedAlertmanagers`.
- If Prometheus does not start after the restart, read its log with `kubectl -n starfleet logs deployment/prometheus`. A YAML error in either file stops the start and the log names the line.
