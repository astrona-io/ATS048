# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-030/module-02/labs/lab-01
```

Submit once before you change anything. Only `other-targets-healthy` and `crowded-series-not-stored` pass: the `crowded` job does not exist, so no ticket series are stored.

## Step 1: Look at what the application exposes

Request the metrics page of the application from inside the cluster and count the samples:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://crowded:8080/metrics
```

You see two comment lines and then lines of the form `lab_ticket_info{ticket_id="t0000"} 1`, one per ticket. There are 200 of them. Each line has a different value of the label `ticket_id`, so each line is a separate time series. A time series is created for every unique combination of metric name and label values.

The number of series, called cardinality, decides how much memory the server needs for the in-memory head block, because every active series keeps an entry there. A label whose values grow without a bound (a ticket number, a user id, a request id) makes the cardinality grow without a bound.

## Step 2: Choose the limit

Prometheus has per-job limits that protect the server. Three are common:

- `sample_limit`: the maximum number of samples a single scrape may return after metric relabeling.
- `label_limit`, `label_name_length_limit`, `label_value_length_limit`: limits for the labels of a series.
- `target_limit`: the maximum number of targets a job may have.

When a scrape returns more samples than `sample_limit`, Prometheus fails that scrape. It does not store part of the samples. The target health becomes `down`, the `lastError` field names the limit, and `up` is 0 for that scrape.

The question asks for a limit of 100. The application returns 200 samples, so the scrape fails.

## Step 3: Add the job

Save this as `prometheus-config.yaml`. The two existing jobs stay as they are:

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
    - job_name: prometheus
      static_configs:
      - targets:
        - localhost:9090
    - job_name: crowded
      sample_limit: 100
      static_configs:
      - targets:
        - crowded:8080
```

Apply it and restart Prometheus:

```sh
kubectl apply -f prometheus-config.yaml
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

## Step 4: Observe the rejection

Wait about 15 seconds, then ask for the targets:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/targets?state=active'
```

The target with the label `job` set to `crowded` has `health` set to `down`. Its `lastError` is a message that says the sample limit was exceeded. The `probe` and `prometheus` targets stay `up`, because limits apply per job.

Query the series that the rejected scrape would have created:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=count(lab_ticket_info)'
```

The `result` list is empty. The failed scrape stored none of the 200 samples. The only series that remain for this job are the automatic ones such as `up`, which has the value 0:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=up{job="crowded"}'
```

## Step 5: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-030/module-02/labs/lab-01 --keep
```

Four checks must pass.

## What each check proved

- `crowded-job-limited` read the active configuration from `/api/v1/status/config` and looked at the `crowded` job block. It required a limit above 0 and below 200. A limit of 500 would let the scrape pass and fails here.
- `crowded-scrape-rejected` required the health `down` and a `lastError` text that mentions the sample limit. A job that is down for another reason, such as a wrong port, fails this check.
- `crowded-series-not-stored` required that no `lab_ticket_info` series exists. It proves that a rejected scrape is discarded as a whole.
- `other-targets-healthy` required the `probe` target to be up.

## If a check fails

- If `crowded-scrape-rejected` fails and the error says connection refused, the target address is wrong. The Service is `crowded` on port 8080.
- If the target is `up` and the series are stored, the limit is not set in the job, or it is set too high.
- A sample limit is a safety net, not a solution. A real fix removes the unbounded label at the source or aggregates it away. The limit makes the failure visible instead of letting the server run out of memory.
