# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-030/module-01/labs/lab-01
```

Submit once before you change anything. Only `server-healthy` passes. The other three checks fail because the flags still have their defaults.

## Step 1: Read the flags the server runs with

Prometheus reports the flags of the running process in its status API. This is the authoritative answer to the question "what limit is active", because a Deployment file shows only what you asked for:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/status/flags
```

The answer is a JSON object. Find the keys `storage.tsdb.retention.time`, `storage.tsdb.retention.size`, `query.timeout` and `query.max-samples`. They show the defaults: 15 days of time retention, no size limit, a query timeout of two minutes and a sample limit of 50000000.

Now look at the arguments in the Deployment:

```sh
kubectl -n starfleet get deployment prometheus -o jsonpath='{.spec.template.spec.containers[0].args}'
```

There are three arguments: `--config.file`, `--storage.tsdb.path` and `--web.enable-lifecycle`. Flags that you do not set keep their defaults.

## Step 2: Understand what each flag limits

Time retention and size retention work on blocks, not on single samples. Prometheus writes recent samples to a write-ahead log and the in-memory head block. Every two hours it compacts the head into an immutable block on disk. The retention logic deletes whole blocks when they are older than the time limit, or when the total size of blocks and write-ahead log passes the size limit. If both flags are set, the first limit that is reached removes data.

A deletion happens only for a block that lies completely outside the retention window. Data therefore stays a little longer than the limit.

`--query.timeout` stops a single query that runs too long. `--query.max-samples` limits how many samples one query may hold in memory at the same time. A query that would pass the limit fails with an error, and the server stays healthy. These two flags protect the server from expensive queries. They do not limit how many series are ingested.

## Step 3: Add the flags

The flags go into the `args` list of the container. A JSON patch with the operation `add` and the path ending in `/-` appends to a list, so the existing arguments stay. Run:

```sh
kubectl -n starfleet patch deployment prometheus --type=json -p '[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--storage.tsdb.retention.time=6h"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--storage.tsdb.retention.size=500MB"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--query.timeout=30s"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--query.max-samples=10000000"}
]'
```

A change to the pod template starts a rollout. Wait for it:

```sh
kubectl -n starfleet rollout status deployment/prometheus
```

If you prefer `kubectl edit deployment prometheus`, add the four lines below the existing three arguments. Keep the indentation of the list.

## Step 4: Check the result

Read the flags again from the new pod:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/api/v1/status/flags
```

The four keys now show `6h`, `500MB`, `30s` and `10000000`. Also check that the server is ready:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://prometheus:9090/-/ready
```

The pod restarted, so the empty data directory started again and the history before the restart is gone. This lab uses an `emptyDir` volume, so a restart always discards the data. A production server needs a persistent volume for this reason.

## Step 5: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-030/module-01/labs/lab-01 --keep
```

Four checks must pass.

## What each check proved

- `retention-time` and `retention-size` read the live flags API, so a value in a file that the process never loaded does not pass.
- `query-limits` required both query flags in one check.
- `server-healthy` required that `/-/ready` answers, that `--config.file` and `--web.enable-lifecycle` are still present, and that the probe target is up. A patch that replaces the whole `args` list removes these flags and fails here.

## If a check fails

- If `retention-size` fails with a different value, check the unit. Prometheus accepts units such as `MB` and `GB`; the flags API returns the text you passed.
- If the check shows the old value, the new pod may not be running yet. Run the rollout status command again.
- If the pod crashes after your change, read `kubectl -n starfleet logs deployment/prometheus`. A mistyped flag name makes Prometheus exit at start with a message about an unknown long flag.
