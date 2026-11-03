# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-030/capstone/labs/lab-01
```

Submit once before you change anything. Only `server-healthy` passes, because the server is healthy. The other checks fail because the flags are at their defaults and the crowded target is scraped without a limit.

## Step 1: See the current state

The server runs with its defaults, so it keeps data for 15 days and has no size cap. List the flags that the running server uses:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/status/flags
```

The entry `storage.tsdb.retention.time` is empty or at its default and `storage.tsdb.retention.size` is `0`, which means no size limit. Then count the stored ticket series:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=count(lab_ticket_info)'
```

The value is 200. One metric with a label such as `ticket_id`, whose values are unbounded, makes the number of series grow without limit. Every series costs memory in the head block and index space on disk, whatever the sample value is.

## Step 2: Understand the two protections

Retention flags and `sample_limit` protect different resources.

- Retention limits how long stored data lives. Prometheus deletes whole blocks that are older than the time limit or that push the total size over the size limit, starting with the oldest. Only persistent blocks are deleted. The write-ahead log and the memory-mapped chunks count toward the total size, but they are not deleted by retention. Retention does not reduce the number of series that arrive.
- `sample_limit` limits what one scrape may add. A scrape that returns more samples than the limit is rejected as a whole. This protects the head block from one misbehaving target.

Retention flags are command-line flags of the server, so changing them needs a new pod. `sample_limit` is part of the configuration file, so it needs a reload or a restart.

## Step 3: Change the configuration

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

```sh
kubectl apply -f prometheus-config.yaml
```

## Step 4: Add the flags to the Deployment

The flags belong to the list `args` of the container `prometheus`. A JSON patch with the operation `add` and the path ending in `/-` appends one item to the list and keeps the existing items:

```sh
kubectl -n starfleet patch deployment prometheus --type=json -p '[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--storage.tsdb.retention.time=12h"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--storage.tsdb.retention.size=1GB"}
]'
kubectl -n starfleet rollout status deployment/prometheus
```

The patch changes the pod template, so Kubernetes starts a new pod, and the new pod reads the changed ConfigMap at the same time. The old samples are lost, because the data directory is an `emptyDir`.

## Step 5: Check the result

Wait about a minute and query:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/status/flags
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/targets?state=active'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=count(lab_ticket_info)'
```

The flags show `12h` and `1GB`. The target with the job `crowded` has `health` set to `down` and a `lastError` that names the sample limit. The count query returns no result, because the rejected scrapes stored nothing.

## Step 6: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-030/capstone/labs/lab-01 --keep
```

Four checks must pass.

## What each check proved

- `retention-flags` read the flags API and required the exact values.
- `crowded-limit-config` read the loaded configuration and required a limit above 0 and below 200.
- `crowded-rejected` required the down state with a sample limit message and no stored ticket series.
- `server-healthy` required readiness, the old flags and a working probe target, so a patch that replaced the argument list fails here.

## If a check fails

- If a flag check fails, look at the pod arguments with a describe of the Deployment. A patch with the operation `replace` on the whole list removes the existing flags.
- If the crowded target stays up, the loaded configuration has no limit or a limit of 200 or more.
- If the server does not become ready, read the pod log. A flag with an invalid value makes Prometheus exit with an error that names the flag.
