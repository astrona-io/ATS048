# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-010/module-01/labs/lab-01
```

Submit once before you change anything. The check `raw-series-intact` passes already, because the `probe` target is scraped and nothing you add will touch it. The other three checks fail because no rule exists yet. That result is expected.

## Step 1: Look at what Prometheus loads

Prometheus has two kinds of input here. The scrape configuration decides what it collects. The rule files decide what it computes from the collected samples. Both are ConfigMaps mounted into the Prometheus pod. Look at the rule ConfigMap:

```sh
kubectl -n starfleet get configmap prometheus-rules -o yaml
```

The value of `rules.yaml` is `groups: []`. An empty list is valid, so Prometheus starts without error and has nothing to evaluate. You can confirm that Prometheus sees no rule groups:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/rules
```

The `shuttle` pod only gives you a shell inside the cluster network that has `wget`. The `groups` list in the answer is empty.

## Step 2: Write the rule group

A rule group has a name, an optional evaluation interval and a list of rules. A recording rule has two fields: `record`, the name of the new series, and `expr`, the PromQL expression Prometheus evaluates at every interval. The result of the expression is stored as a new series with that name.

Both expressions use `rate`. `rate` works on counters: it takes the range of samples of the last minute and returns the average increase per second. Then `sum by (job)` adds the rates of all series (one per `status` value) and keeps only the `job` label.

Save this as `rules-pipeline.yaml`. It replaces the whole ConfigMap, so keep the object name and the key exactly as shown:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
  namespace: starfleet
data:
  rules.yaml: |
    groups:
    - name: lab_pipeline
      interval: 5s
      rules:
      - record: job:lab_requests_total:rate1m
        expr: sum by (job) (rate(lab_requests_total[1m]))
      - record: job:lab_requests_errors:ratio_rate1m
        expr: sum by (job) (rate(lab_requests_total{status="500"}[1m])) / sum by (job) (rate(lab_requests_total[1m]))
```

Apply it:

```sh
kubectl apply -f rules-pipeline.yaml
```

## Step 3: Make Prometheus read the file

Kubernetes updates a mounted ConfigMap file inside the pod after a delay of up to about a minute. Even then, Prometheus does not notice the change until it reloads. This lab starts Prometheus with `--web.enable-lifecycle`, so `POST /-/reload` would work once the file has changed. The simplest way that always works is to restart the Deployment, because a new pod reads the current ConfigMap at start:

```sh
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

The restart also starts an empty time series database, because the data directory is an `emptyDir` volume. Wait about a minute so that Prometheus can scrape the `probe` target a few dozen times. A one-minute `rate` needs at least two samples inside the window.

## Step 4: Check the rules

Ask the rules API which groups are loaded and whether the last evaluation worked:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/rules
```

Each rule in the answer has a `health` field. It must be `ok`. A rule with `health` of `err` has a `lastError` field with the reason, for example a typo in a metric name or function.

Now query the two recorded series. The query goes in the `query` parameter of the instant query endpoint:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=job:lab_requests_total:rate1m'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=job:lab_requests_errors:ratio_rate1m'
```

The first series has the labels `__name__` and `job`, and no `status` label, because `sum by (job)` removed it. The second value is a ratio between 0 and 1. The traffic generator sends one failing request in every ten, so the ratio is close to 0.1.

## Step 5: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-010/module-01/labs/lab-01 --keep
```

Four checks must pass.

## What each check proved

- `rules-loaded` read `/api/v1/rules` and looked for both rule names, with type `recording` and health `ok`, in a file under `/rules/`. It proves that Prometheus loaded the file, not only that the ConfigMap changed.
- `request-rate-recorded` queried the new series and required exactly the labels `__name__` and `job`. A rule that forgot `sum by (job)` keeps the `status` label and fails here.
- `error-ratio-recorded` required a value between 2 and 30 percent. A rule that divides by the wrong denominator, or compares a counter with a rate, falls outside that range.
- `raw-series-intact` queried `up` and the raw counter. Recording rules only add series; the source samples stay.

## If a check fails

- If `rules-loaded` fails, run the rules API call from step 4. An empty `groups` list means Prometheus did not reload the file. A rule with `health` of `err` shows its reason in `lastError`.
- If a rule appears but queries return an empty result, wait one more evaluation interval. A new rule produces its first sample after its first evaluation.
- If the YAML is rejected on restart, check the pod: `kubectl -n starfleet logs deployment/prometheus`. Prometheus refuses to start with an invalid rule file and prints the line number.
