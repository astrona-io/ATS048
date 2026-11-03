# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-020/module-02/labs/lab-01
```

Submit once before you change anything. All three checks fail: the instance label is `probe:8080`, there is no `tier` label, and `lab_queue_depth` is stored.

## Step 1: Look at the labels before you change them

Every target has labels before relabeling and labels after it. Prometheus shows both in the targets API. `discoveredLabels` are the labels before relabeling, including the internal ones that start with two underscores. `labels` are what remains after `relabel_configs`:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/targets?state=active'
```

For the `probe` target, `discoveredLabels` has `__address__` set to `probe:8080`, `__metrics_path__`, `__scheme__`, `__scrape_interval__`, `job`, and `team`. The final `labels` has `instance` set to `probe:8080`, because Prometheus copies `__address__` to `instance` when no rule has set `instance`.

## Step 2: Know the two relabeling stages

There are two lists of rules, and they run at different times on different data.

- `relabel_configs` runs once per target, before Prometheus sends the scrape request. It can change which targets are scraped and which labels a target has. It can drop the whole target.
- `metric_relabel_configs` runs on every sample after the scrape, before storage. It can change or drop single series.

The first two tasks change the target, so they belong in `relabel_configs`. The third task removes one metric by name, which only exists after the scrape, so it belongs in `metric_relabel_configs`.

A rule with the action `replace` (the default action) concatenates the values of `source_labels`, matches the regular expression `regex` (default `(.*)`) and writes `replacement` into `target_label`. With no `source_labels`, the concatenated value is empty. The default regular expression matches the empty string, so the rule always applies and writes the constant.

The action `drop` removes the sample when the regular expression matches the concatenated source labels. The metric name is stored in the label `__name__`.

## Step 3: Edit the configuration

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
      static_configs:
      - labels:
          team: starfleet
        targets:
        - probe:8080
      relabel_configs:
      - target_label: tier
        replacement: backend
      - target_label: instance
        replacement: probe-main
      metric_relabel_configs:
      - source_labels: [__name__]
        regex: lab_queue_depth
        action: drop
    - job_name: prometheus
      static_configs:
      - targets:
        - localhost:9090
```

Apply it and restart Prometheus so it loads the file:

```sh
kubectl apply -f prometheus-config.yaml
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

## Step 3: Check the result

Wait about 15 seconds. The targets API now shows `labels` with `instance` set to `probe-main` and `tier` set to `backend`. The `scrapeUrl` is still `http://probe:8080/metrics`, because `__address__` was not changed. Only the `instance` label was rewritten:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/targets?state=active'
```

Query the dropped metric and a kept metric:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=lab_queue_depth'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=lab_last_success_timestamp_seconds'
```

The first answer has an empty `result` list. The second has one series.

## Step 4: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-020/module-02/labs/lab-01 --keep
```

Three checks must pass.

## What each check proved

- `instance-relabeled` queried `up` with the new `instance` value and required the value 1. The scrape still worked, so the rewrite changed only the label and not the address.
- `tier-label-added` queried the counter with `tier="backend"`.
- `queue-depth-dropped` required three facts: the dropped metric is absent, and two other metrics of the same job are present. A rule that drops the whole job, or one with a regular expression that is too broad, fails the other two.

## If a check fails

- If `instance-relabeled` fails because `up` is missing, the rule probably changed `__address__` and the scrape went to a wrong address. Rewrite the label `instance`, not `__address__`.
- If `queue-depth-dropped` fails with a still-stored metric, the rule is in `relabel_configs`. That list sees target labels and no metric names, so it never matches. Move the rule to `metric_relabel_configs`.
- A regular expression in a relabel rule is anchored. `lab_queue` alone does not match `lab_queue_depth`; use the complete name or `lab_queue.*`.
