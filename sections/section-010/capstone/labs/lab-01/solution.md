# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-010/capstone/labs/lab-01
```

Submit once before you change anything. All four checks fail. Nothing in the pipeline works yet, and the lab has two faults on two different stages.

## Step 1: Follow the alert from the end of the pipeline back

An alert travels through four stages. Prometheus evaluates the rule, Prometheus sends the firing alert to Alertmanager, Alertmanager groups it, and Alertmanager posts a notification to the receiver. When nothing arrives, check the stages from the start and stop at the first one that does not work.

Stage 1 is the rule. List the rules and their health:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/rules
```

The rule `LabHighErrorRatio` is listed and its `health` is `ok`. Health `ok` only means that the expression evaluated without an error. It does not mean that the expression found data.

## Step 2: Check that the expression finds data

Run the two halves of the expression separately:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=sum(rate(lab_request_total[1m]))'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=sum(rate(lab_requests_total[1m]))'
```

The first query returns an empty `result` list. The second returns one value. The application exposes the counter `lab_requests_total`. The rule uses `lab_request_total`, which does not exist. A selector on a metric name that does not exist is not an error in PromQL. It returns no series, so the division returns no series, so the comparison returns no series, and a rule with no result never creates an alert.

This is the first fault. The metric name in the rule must be `lab_requests_total`, in both places.

## Step 3: Check that Prometheus reaches Alertmanager

Stage 2 is the connection to Alertmanager:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/alertmanagers
```

The list `activeAlertmanagers` is built from the configuration, not from a health test. It contains an entry whose `url` ends in port 9094. Alertmanager listens on 9093 in this cluster: the Service `alertmanager` exposes that port. Port 9094 is the default cluster gossip port of Alertmanager, not its HTTP API port. Prometheus sends alerts to the address you give it, and a wrong port does not stop the rule evaluation. The alert is visible in the Prometheus alerts API but never reaches Alertmanager. This is the second fault. The check in this lab looks for an entry with port 9093.

## Step 4: Write the corrected files

Save this as `prometheus-fixed.yaml`:

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

Apply it and restart Prometheus so that it reads both files:

```sh
kubectl apply -f prometheus-fixed.yaml
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

The Deployment mounts both ConfigMaps as files. A restart is the simplest way to be sure that the new content is loaded. The restart discards the stored samples, because the data directory is an `emptyDir`, so the rate needs about a minute of new scrapes before it has a value.

## Step 5: Watch the alert move through its states

Wait one to two minutes, then query the state of the alert:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/alerts
```

The alert is first `pending`. It stays pending while the condition is true for less than the `for` duration of 10 seconds. After that it is `firing`. Then check Alertmanager and the receiver:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://alertmanager:9093/api/v2/alerts
kubectl -n starfleet exec shuttle -- wget -qO- http://probe:8080/hooks
```

Alertmanager lists the alert with the label `severity` set to `page`. The receiver returns a JSON list with the notification payloads. Each payload has an `alerts` list, and each alert has `labels` with the `alertname`. Alertmanager waits `group_wait`, 5 seconds in this lab, before the first notification of a new group.

## Step 6: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-010/capstone/labs/lab-01 --keep
```

Four checks must pass.

## What each check proved

- `alertmanager-connected` required an entry with `alertmanager:9093` in the list of active Alertmanagers. It fails while the port is 9094.
- `alert-fires` required the state `firing`. It fails while the metric name is wrong, even though the rule is healthy.
- `alert-in-alertmanager` read the Alertmanager API and proved that stage 2 works from the Alertmanager side.
- `webhook-delivered` read the receiver. It proves stage 4, the whole path from rule to notification.

## If a check fails

- If `alert-fires` fails after the fix, wait longer. After a restart the rate needs samples from at least two scrapes inside the one-minute window.
- If `alertmanager-connected` fails, read the `activeAlertmanagers` list again and compare the port with the Service.
- If `webhook-delivered` fails while Alertmanager has the alert, wait for the group interval of 10 seconds and request the hooks again.
