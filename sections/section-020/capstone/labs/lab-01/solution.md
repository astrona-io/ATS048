# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-020/capstone/labs/lab-01
```

Submit once before you change anything. All four checks fail.

## Step 1: Read why each target is down

Prometheus records the reason for every failed scrape in the targets API:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/targets?state=active'
```

Find the entries with the job `probe` and the job `exporter`. Their `health` is `down` and their `lastError` is a message. The two jobs fail for different reasons.

## Step 2: Find the fault of the probe job

A scrape job requests the path in `metrics_path`. The default is `/metrics`. The job `probe` sets `metrics_path: /metric`. The application answers a request to that path with a 404 status, and Prometheus treats a status other than 200 as a failed scrape. The `lastError` says that the server returned an HTTP status of 404. Set the path back to `/metrics`, or remove the line, because `/metrics` is the default.

## Step 3: Find the fault of the exporter job

The job `exporter` targets `exporter:9090`. Nothing listens on that port. The `lastError` is a connection error. The application listens on 8080. The target address is the host and the port of the HTTP server that serves the metrics, so the port must match what the application listens on.

## Step 4: Drop one metric and add one label

Relabeling has two stages. `relabel_configs` runs on the target before the scrape. `metric_relabel_configs` runs on every scraped series after the scrape and before storage. Dropping a metric by name is a task for the second stage, because the name `__name__` exists only after the scrape:

```yaml
metric_relabel_configs:
- source_labels: [__name__]
  regex: lab_queue_length
  action: drop
```

The regular expression is anchored at both ends. `lab_queue_length` matches that name exactly, and no other metric.

A label that every series of a target must carry is a target label. The simplest way is `labels` in the `static_configs` entry. The labels apply to every series of that target.

## Step 5: Write the configuration

Save this as `prometheus-config.yaml`:

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
    rule_files:
    - /rules/*.yaml
    scrape_configs:
    - job_name: probe
      metrics_path: /metrics
      static_configs:
      - labels:
          team: starfleet
        targets:
        - probe:8080
    - job_name: prometheus
      static_configs:
      - targets:
        - localhost:9090
    - job_name: exporter
      static_configs:
      - labels:
          env: training
        targets:
        - exporter:8080
      metric_relabel_configs:
      - source_labels: [__name__]
        regex: lab_queue_length
        action: drop
```

Apply it and restart Prometheus:

```sh
kubectl apply -f prometheus-config.yaml
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

## Step 6: Check the result

Wait for the next scrapes and query:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=up'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=lab_workers'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=lab_queue_length'
```

`up` is 1 for the three jobs. `lab_workers` has the label `env` with the value `training`. The query for `lab_queue_length` returns no series from the exporter. The probe application exposes a different metric, `lab_queue_depth`, so the name `lab_queue_length` does not exist elsewhere.

## Step 7: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-020/capstone/labs/lab-01 --keep
```

Four checks must pass.

## What each check proved

- `probe-up` required `up` equal to 1 for the job `probe`.
- `exporter-up` did the same for the exporter. Both fail for the reasons in steps 2 and 3.
- `queue-length-dropped` required that the dropped name is absent while `lab_workers` and the two counter series remain. A rule that drops all series of the job fails here.
- `env-label` counted series with and without the label. It requires every series of the job to carry it.

## If a check fails

- If a target is still down, read `lastError` again after the next scrape.
- If `queue-length-dropped` fails, check that the rule is under `metric_relabel_configs`, not under `relabel_configs`.
- If the label is missing on some series, check that the labels are on the exporter job and not on another job.
