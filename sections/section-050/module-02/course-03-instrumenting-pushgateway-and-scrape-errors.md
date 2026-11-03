---
draft: true
exam_objectives:
- Exposition Format
---
# Client Libraries, The Pushgateway And Scrape Errors

Someone has to write the page. In most cases a client library writes it for you, and in a few cases a short-lived job pushes it to a Pushgateway instead of waiting to be scraped. When the page or the connection is wrong, Prometheus reports a specific error, and each error points to one cause. This lesson covers how an application produces its page, how a small exporter works, what the Pushgateway accepts, and how to match a scrape error to its cause.

## What a client library does

A client library is a package for a programming language, such as `prometheus_client` for Python or `client_golang` for Go, that keeps metrics in memory and renders them in the exposition format. The application does not write text lines. It creates metric objects, updates them in the code, and exposes an HTTP handler for them.

The library does four jobs that are easy to get wrong by hand:

- It keeps a registry of all metrics and renders each family together, with `# HELP` and `# TYPE` lines first.
- It escapes label values and help text.
- It adds the `+Inf` bucket to every histogram and keeps the buckets in order.
- It chooses the format from the `Accept` header of the request. When the scraper asks for OpenMetrics, the library writes `_total` samples, `_created` samples and the `# EOF` line, and it answers with the OpenMetrics content type.

Because of this, a fault in a page from a client library is rare. Faults appear in hand-written pages and in exporters that build lines with string formatting.

## Instrumenting an application

To instrument an application means to add metrics to its code. The steps are the same in every language. This example uses Python and shows the code only, so you read it and do not run it here.

```python
from prometheus_client import Counter, Gauge, Histogram, start_http_server

JOBS = Counter("lab_jobs", "Jobs processed by the worker.", ["result"])
WORKERS = Gauge("lab_workers", "Number of running workers.")
DURATION = Histogram("lab_job_duration_seconds", "Job duration in seconds.")

start_http_server(8000)

WORKERS.set(4)
JOBS.labels(result="ok").inc()
with DURATION.time():
    do_work()
```

Each line has a role:

1. The constructors declare the metrics with a name, a help text and the label names. The library adds the suffix `_total` to the counter, so the series is `lab_jobs_total`.
2. `start_http_server` starts an HTTP server in a thread of the application. It serves the page on `/metrics`.
3. `set` changes a gauge, `inc` adds one to a counter, and `time` measures a block and puts the duration into the histogram.

The labels of a metric are declared once and then given a value on every use. Label values that come from users or from unbounded data create a new series for each value, so choose label values from a small, fixed set.

## A small custom exporter

An exporter is a program that reads data from a system that has no Prometheus support and serves it as a page. The exporter in the playground is the smallest example: it reads a text file and answers on `/metrics`. The work of every exporter has the same four steps.

1. Receive the HTTP request from Prometheus on the metrics path.
2. Read the values from the source system at request time, not on a timer, so each scrape returns current data.
3. Render the values in the exposition format with correct names, types and escaping.
4. Answer with the right `Content-Type` and status code 200.

The exporter should read the source quickly. If the answer takes longer than the scrape timeout, the scrape fails. A library for the exporter's language is the best way to render the lines, because the library handles the escaping and the format negotiation.

## The Pushgateway

Most targets are scraped, but a batch job may finish before Prometheus gets a chance to scrape it. The Pushgateway is a separate service that accepts metrics from such jobs over HTTP and holds them, and Prometheus scrapes the Pushgateway like any other target. It is meant for the results of service-level batch jobs, and it is not a way to turn Prometheus into a push system.

A job pushes its page with an HTTP request to a path of this form:

```text
/metrics/job/<JOB_NAME>/<LABEL_NAME>/<LABEL_VALUE>
```

The path holds the job name and optional pairs of label names and values. Together they form the grouping key. The body is a page in the text format, version 0.0.4, where every line ends with a line feed. The default port of the Pushgateway is 9091. For example, with `curl` the command below pushes one gauge to the group `job=backup` and `instance=db1`.

```text
echo "lab_backup_last_success 1" | curl --data-binary @- http://pushgateway:9091/metrics/job/backup/instance/db1
```

The method selects what happens to old data of the same group:

- `PUT` replaces all metrics of the group.
- `POST` replaces only the metrics whose names appear in the new push, and keeps the others.
- `DELETE` removes all metrics of the group.

The Pushgateway adds the gauges `push_time_seconds` and `push_failure_time_seconds` to each group. They hold the time of the last successful and the last failed push, and you can alert on a group that has not been pushed for a long time.

Pushed data stays on the Pushgateway until someone deletes it, so Prometheus keeps scraping the last value even if the job died. This is why the Pushgateway has its own pitfalls. When Prometheus scrapes it, the scrape configuration normally sets `honor_labels: true`. Without it, Prometheus renames the `job` and `instance` labels of the pushed data to `exported_job` and `exported_instance`, because it wants to set its own.

## Scrape errors and their causes

When a scrape fails, `up` is 0 and the targets API holds the error text in `lastError`. The text points to the layer of the failure, and you fix the layer that it names.

| What you see | Layer | Likely cause |
| --- | --- | --- |
| A connection error such as `connection refused` or `no such host` | Network | The target is down, the port is wrong, or the name does not resolve |
| `context deadline exceeded` | Timeout | The target answers slower than the scrape timeout |
| `server returned HTTP status 404` or another status outside 2xx | HTTP | The path is wrong, or the application reports an error |
| An error about the content type | Header | The `Content-Type` is missing, invalid or unsupported |
| An error with a line number and a parse message | Body | An invalid line in the page |
| An error that the data does not end with `# EOF` | Body | An OpenMetrics response without the end marker |

The rows differ in where you look next. For a network error you check the Service and the pod. For a status error you request the path yourself. For a body error you read the line that the message names. For a content type error you print the headers.

## Find a failure on the playground

The job `exporter` negotiates OpenMetrics. Read the state of its target:

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/targets?state=active'
```

Find the entry with `job` set to `exporter` and read `health` and `lastError`. In the playground the page is valid, so `health` is `up` and the error is empty. To see an error, you break the page on purpose. Save this as `exporter-metrics.yaml`. It is a page that Prometheus reads as OpenMetrics, but it has no `# EOF` line:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: exporter-metrics
  namespace: starfleet
data:
  metrics.txt: |
    # HELP lab_workers Number of running workers.
    # TYPE lab_workers gauge
    lab_workers 4
```

Apply it and restart the Deployment so that the new pod serves it:

```sh
kubectl apply -f exporter-metrics.yaml
kubectl -n starfleet rollout restart deployment/exporter
kubectl -n starfleet rollout status deployment/exporter
```

Wait a few seconds for the next scrape and read the targets again. The `health` is now `down`, and `lastError` says that the data does not end with `# EOF`. Add the line `# EOF` at the end of the page, apply, restart and check again.

## What you know now

You know that client libraries keep a registry, escape values, complete histograms and choose the format from the `Accept` header, so faults come mainly from hand-written pages. You know the four steps of an exporter and how the Pushgateway takes a page by `PUT`, `POST` or `DELETE` on a path with a grouping key. You can match a scrape error to the network, timeout, status, header or body layer. What remains is to practise the repair on a real page.

## Common pitfalls

> [!WARNING]
> - Writing exposition lines by hand in a real application instead of using a client library. Escaping and the `+Inf` bucket are easy to get wrong.
> - Using labels with unbounded values, such as user identifiers. Each value creates a new series.
> - Using the Pushgateway for a service that is running. Scrape it directly. The Pushgateway keeps the last value forever until someone deletes it.
> - Scraping the Pushgateway without `honor_labels: true`. The pushed `job` and `instance` labels become `exported_job` and `exported_instance`.
> - Reading an exporter's data on a timer and serving the cached value. The scrape then returns old data without any sign of it.
> - Blaming the format when the error is a timeout or a status code. Read `lastError` first.
