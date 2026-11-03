# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-050/module-01/labs/lab-01
```

Submit once before you change anything. All four checks fail because the page cannot be parsed.

## Step 1: Read the error Prometheus reports

Prometheus fetches the page with an HTTP request and parses the body line by line. If one line is invalid, the parser stops and Prometheus treats the whole scrape as failed: the target is `down` and no sample of that scrape is stored. The targets API shows the reason:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/targets?state=active'
```

Find the target with the label `job` set to `exporter`. Its `lastError` field holds the parser message. It names the line number of the first invalid line, so you fix problems one at a time. Request the page yourself to see the lines:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://exporter:8080/metrics
```

## Step 2: Know the rules of one sample line

A sample line has the form `metric_name{label="value",...} value`. These rules apply:

- A metric name matches `[a-zA-Z_:][a-zA-Z0-9_:]*`. A hyphen is not allowed.
- Label names match `[a-zA-Z_][a-zA-Z0-9_]*`.
- A label value is always inside double quotes. Inside the quotes, a backslash, a double quote and a newline are written as `\\`, `\"` and `\n`.
- The value is a floating-point number. It may also be `NaN`, `+Inf` or `-Inf`. A word such as `four` is not a number.
- A `# TYPE` line must come before the first sample of that metric and must appear only once per metric name.

The page has three faults. In `lab_jobs_processed_total{queue=default,...}` the value of `queue` has no quotes. The gauge `lab_workers` has the value `four`. The last metric is written as `lab-queue-length`, which has hyphens, and does not match its `# TYPE` line, which says `lab_queue_length`.

## Step 3: Write the correct page

Save this as `exporter-metrics.yaml`. The ConfigMap name and the key stay the same:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: exporter-metrics
  namespace: starfleet
data:
  metrics.txt: |
    # HELP lab_jobs_processed_total Jobs processed by the worker, by result.
    # TYPE lab_jobs_processed_total counter
    lab_jobs_processed_total{queue="default",result="ok"} 1027
    lab_jobs_processed_total{queue="default",result="error"} 13
    # HELP lab_workers Number of running workers.
    # TYPE lab_workers gauge
    lab_workers 4
    # HELP lab_queue_length Jobs waiting in the queue.
    # TYPE lab_queue_length gauge
    lab_queue_length 7
```

Apply it:

```sh
kubectl apply -f exporter-metrics.yaml
```

## Step 4: Make the pod serve the new content

A ConfigMap mounted as a volume updates in the pod after a delay of up to about a minute. A restart of the Deployment avoids the wait, because the new pod mounts the current ConfigMap:

```sh
kubectl -n starfleet rollout restart deployment/exporter
kubectl -n starfleet rollout status deployment/exporter
```

Request the page again to see the new content:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://exporter:8080/metrics
```

## Step 5: Check the result in Prometheus

Wait for the next scrape, which is at most two seconds away, then query:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=up{job="exporter"}'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=lab_jobs_processed_total'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/metadata?metric=lab_workers'
```

`up` is 1. The counter has two series, one for each `result` value. The metadata answer lists the type `gauge` and the help text from the `# HELP` line.

## Step 6: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-050/module-01/labs/lab-01 --keep
```

Four checks must pass.

## What each check proved

- `exporter-scrape-ok` required `up` equal to 1. A page with any invalid line cannot pass.
- `counter-series` required the two exact series and values. It proves the quotes around the label value and the number format.
- `gauge-values` required the values 4 and 7. The second also proves that the metric name is valid and matches its type line.
- `types-declared` read the metadata API. Prometheus learns the types from the `# TYPE` lines of the page, so the check proves that the type lines are in the right place.

## If a check fails

- If `up` is still 0, read `lastError` again. The first error you fixed may have hidden a second one on a later line.
- If the page in the pod is still the old one, the pod has not restarted. Run the rollout status command and request the page again.
- If `types-declared` fails while the series exist, a `# TYPE` line is missing or comes after the first sample of its metric.
