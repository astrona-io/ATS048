---
draft: true
exam_objectives:
- Understanding Prometheus Limitations
---
# Protecting The Server With Sample And Label Limits

Prometheus trusts what its targets expose. A scrape returns whatever lines the application writes, and the server stores every one. If a developer ships a version that adds a label with a new value for every user or every ticket, the number of series from that target can grow from hundreds to millions in an hour. The memory of the server grows with it, and the damage is not limited to that one application, because all targets share one server. This lesson shows the per-job limits that Prometheus offers against this, what happens when a limit is exceeded and how to watch for it.

## A target that grows without a bound

The playground has an application named `crowded`. For every open support ticket, it exposes one series of the metric `lab_ticket_info`, and each series has its own value of the label `ticket_id`. Today there are 200 tickets. The number of series equals the number of tickets, so it grows every time a ticket is opened.

<!-- astrona:playground:renew -->

Read the metrics page of the application:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://crowded:8080/metrics
```

After two comment lines you see lines such as `lab_ticket_info{ticket_id="t0000"} 1`, one for each ticket. Count the series that Prometheus holds for it:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=count(lab_ticket_info)'
```

The playground Prometheus already scrapes this target without any limit, so the answer is 200. Each value of `ticket_id` is a separate series with its own entry in the head block. The metric itself is useful for a ticket count, but the `ticket_id` label turns a count into a list. If the ticket system grows to a million tickets, the server must track a million series for one metric.

## The scrape limits

Prometheus has limits that you set per scrape job, in the `scrape_config` of the job. All of them default to 0, which means no limit.

- `sample_limit` is the largest number of samples that one scrape may return, counted after metric relabeling.
- `label_limit` is the largest number of labels that one sample may have.
- `label_name_length_limit` and `label_value_length_limit` are the largest length in bytes of a label name and of a label value.
- `target_limit` is the largest number of targets that the job may have after target relabeling. This limit is marked experimental in the documentation.
- `body_size_limit` is the largest size of the uncompressed response body. This one is also experimental.

The rule that you must remember is what happens on a violation. For `sample_limit`, the documentation states that if more samples than the limit are present, the entire scrape is treated as failed. Prometheus does not store the first 100 samples and drop the rest. It stores none of the samples of that scrape. The label limits behave the same way: one sample that breaks the limit fails the entire scrape.

The reason is safety. A partial result would look like a working target but hold an arbitrary part of the data, and a dashboard would show wrong totals without any sign of it. A failed scrape is visible: the target is down, and the problem gets attention.

Limits apply per job, so a job that breaks its limit does not affect the other jobs. The server also does not slow down for the other targets.

## Set a limit on the crowded job

The limit goes into the job block in the Prometheus configuration. In this playground the configuration is the ConfigMap `prometheus-config`, key `prometheus.yaml`, and Prometheus reads it from a mounted file. Save the complete ConfigMap with the new line `sample_limit: 100` in the `crowded` job as `prometheus-config.yaml`:

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

Apply it:

```sh
kubectl apply -f prometheus-config.yaml
```

Prometheus does not notice a changed file by itself. The server was started with `--web.enable-lifecycle`, so you can tell it to reload, but a ConfigMap volume also needs some time to show the new file inside the pod. The simplest way in this playground is to restart the pod, and it reads the file at start:

```sh
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

Because the data directory is an `emptyDir` volume, the new pod starts with an empty database. On a server with a persistent volume, samples that were stored before the limit stay until the retention removes them.

## Observe the rejection

Wait about fifteen seconds so that Prometheus completes a few scrapes, then read the target list:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/targets?state=active'
```

Find the target with the label `job` set to `crowded`. Its `health` is `down`, and `lastError` is a message that names the sample limit. The `probe` and `prometheus` targets stay `up`. Now count the ticket series again:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=count(lab_ticket_info)'
```

The `result` list is empty, because the rejected scrapes stored no ticket series. The automatic series is still written, and it records the failure:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=up%7Bjob%3D%22crowded%22%7D'
```

The value of `up` for the `crowded` job is 0. The server also counts the rejections in its own metric `prometheus_target_scrapes_exceeded_sample_limit_total`. Query it to see that the counter increases at each scrape interval.

## Choosing a limit

A limit that is too low breaks a healthy target, and a limit that is too high protects nothing. A good method is to look at the normal size of the target, using `scrape_samples_scraped` for the job, and then to set the limit with a margin, for example about twice the normal size. Then alert on `up == 0` for the job and on the rejection counter, so that a growing target is a signal that someone sees, and not a silent gap in the data.

A limit is a safety net and not a fix. A target that reaches the limit must be repaired in the application, by removing the unbounded label, or in the scrape configuration with `metric_relabel_configs` that drops or rewrites the label. The limit counts samples after metric relabeling, so relabeling that drops the unwanted series can bring the target below the limit again.

## Other ways to protect the server

The scrape limits are not the only protection. A server-wide limit on query cost comes from the flags `--query.timeout` and `--query.max-samples`. The disk is protected by the retention flags. Memory is protected best by controlling what is scraped: review new metrics and labels before release, list the series count by metric name from the status API and alert when the number of head series grows faster than expected.

You now know that Prometheus trusts its targets, that the scrape limits fail a whole scrape instead of storing part of it, and how to see the failure in the target list, in `up` and in the rejection counter. Together with the retention flags, this gives the server a set of limits that protects the disk, the memory and the query path.

## Common pitfalls

> [!WARNING]
> - Do not expect a partial result. When a scrape exceeds `sample_limit`, none of its samples is stored, and the target shows `down`.
> - Do not set a limit without alerting on `up == 0`. A rejected target looks like a gap in the data unless you watch for it.
> - A limit counts samples after metric relabeling. Relabeling that drops series can bring a target under the limit.
> - Limits apply per job. A limit on one job does not protect the server from another job that has no limit.
> - Do not raise the limit just to make the error disappear. Find the label that grows without a bound.
