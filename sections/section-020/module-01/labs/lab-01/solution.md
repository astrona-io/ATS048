# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-020/module-01/labs/lab-01
```

Submit once before you change anything. Only `self-scrape-kept` passes. The other checks fail because the probe target is wrong.

## Step 1: Find out why the target is down

Prometheus reports the state of every target in its targets API. Each target has a `health` value of `up` or `down`, and a `lastError` field with the reason of the last failed scrape:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/targets?state=active'
```

Find the target with the label `job` set to `probe`. Its `scrapeUrl` is `http://probe:8081/metrics`. The `health` value is `down` and `lastError` reports that the connection was refused. Nothing listens on port 8081.

The `up` series carries the same fact as a number. A value of 0 means the last scrape failed:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=up'
```

## Step 2: Fix the target and the timing

Three changes are needed in the job `probe`. First, the target must be `probe:8080`. The scrape URL is built from the scheme (`http` by default), the address in `targets` and the `metrics_path` (`/metrics` by default).

Second, `scrape_interval` and `scrape_timeout` can be set per job. A job value overrides the global value. The timeout must not be longer than the interval, otherwise Prometheus rejects the configuration. A timeout of 3 seconds in a 5 second interval is valid.

Third, a target group has `targets` and an optional `labels` map. Prometheus adds these labels to every target of the group, and the target labels then end up on every series scraped from it.

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
      scrape_interval: 5s
      scrape_timeout: 3s
      static_configs:
      - labels:
          env: lab
        targets:
        - probe:8080
    - job_name: prometheus
      static_configs:
      - targets:
        - localhost:9090
```

Apply it:

```sh
kubectl apply -f prometheus-config.yaml
```

## Step 3: Validate the file and reload

Prometheus ships a tool that checks a configuration file without starting the server. It is called `promtool`, and it is inside the Prometheus container image. You can check the mounted file in the running pod before the new version arrives, but the ConfigMap volume updates with a delay. A restart is the most direct way to load the new file:

```sh
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

If the file were invalid, the new pod would not become ready and `kubectl -n starfleet logs deployment/prometheus` would show the error.

## Step 4: Check the result

Wait about 15 seconds, then look at the targets again:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/targets?state=active'
```

The `probe` target now has `health` set to `up`, `scrapeInterval` of `5s` and `scrapeTimeout` of `3s`. Its labels include `env` with the value `lab`, next to `job` and `instance`. Check that the label reaches the stored series:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=lab_requests_total'
```

Every result has `env` in its `metric` object.

## Step 5: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-020/module-01/labs/lab-01 --keep
```

Four checks must pass.

## What each check proved

- `probe-target-up` required an `up` series with the value 1. It proves a real scrape succeeded after the change.
- `probe-scrape-timing` read the active targets and compared `scrapeInterval` and `scrapeTimeout`. It proves the values are set on the job and loaded.
- `probe-env-label` queried the stored counter with a label matcher. Labels from a target group become series labels.
- `self-scrape-kept` required the `prometheus` job to keep the global interval of 2 seconds, so a change in the global section does not pass.

## If a check fails

- If `probe-scrape-timing` fails and the target is up, you may have set the values in the `global` section. A global value applies to all jobs and changes the `prometheus` job as well.
- If Prometheus does not become ready after the restart, read its log. A `scrape_timeout` that is larger than `scrape_interval` is a typical configuration error.
- If `probe-env-label` fails right after the restart, wait one more scrape interval. The label exists only on samples collected after the new configuration loaded.
