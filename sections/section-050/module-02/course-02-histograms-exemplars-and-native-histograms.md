---
draft: true
exam_objectives:
- Exposition Format
---
# Histograms, Exemplars And Native Histograms

A histogram shows how fast requests are, and a trace shows why one request was slow. OpenMetrics lets a histogram bucket carry a pointer to a trace, and a newer histogram type removes the need to choose bucket bounds in advance. This lesson covers the histogram rules in OpenMetrics, what goes wrong when a bucket is missing, exemplars and native histograms. The last two are concepts that you must recognise, and you will not build them by hand.

## A complete OpenMetrics histogram

A histogram page has the same lines as in the classic format: `_bucket` lines with the label `le`, a `_sum` and a `_count`. OpenMetrics is stricter about two things. Every histogram must have the bucket `le="+Inf"`, and the bucket values must be integers that do not decrease from one bucket to the next. The `le` values must be in increasing order.

```text
# HELP lab_job_duration_seconds Job duration in seconds.
# TYPE lab_job_duration_seconds histogram
lab_job_duration_seconds_bucket{le="0.1"} 600
lab_job_duration_seconds_bucket{le="0.5"} 900
lab_job_duration_seconds_bucket{le="1"} 1000
lab_job_duration_seconds_bucket{le="+Inf"} 1040
lab_job_duration_seconds_sum 412.5
lab_job_duration_seconds_count 1040
# EOF
```

The page is the page of the playground. It holds 1040 observations, and the `+Inf` bucket counts all of them. The line `# EOF` closes it. The `+Inf` value must equal `_count`.

## What happens when the +Inf bucket is missing

Prometheus parses a page without the `+Inf` bucket without complaint, as long as the other rules hold. The target is `up`, and the series are stored. The error appears later, in the result of `histogram_quantile`. The function takes the total count from the bucket with the highest bound, which must be `+Inf`. When the bucket is missing, the function returns `NaN`.

This fault is hard to see, because nothing is marked as failed. A graph of the 90th percentile shows no data, and the scrape is healthy. The way to find it is to compare the `_bucket` series of a histogram. Query the series with the label `le="+Inf"`, and if the result is empty, the histogram is incomplete.

## Check it on the playground

Ask Prometheus for the `+Inf` bucket and for the count. In the playground both queries return a series, and both have the same value.

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=lab_job_duration_seconds_bucket{le="%2BInf"}'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=lab_job_duration_seconds_count'
```

The first query writes the `+` of `+Inf` as `%2B`, because a plain `+` in a URL query string is read as a space. Prometheus decodes `%2B` back to `+`, so the selector matches the bucket `le="+Inf"`. Now compute the quantile.

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=histogram_quantile(0.9,lab_job_duration_seconds_bucket)'
```

The answer is a number between 0.5 and 1. The rank for the 0.9 quantile is 936 of 1040 observations, which lies between the cumulative counts of the bucket 0.5 and the bucket 1, so the estimate falls inside that bucket. If you remove the line with `le="+Inf"` from the ConfigMap, apply it and restart the Deployment, the same query returns `NaN`.

## Exemplars

An exemplar is one example observation that is attached to a sample. It holds a value, an optional timestamp and a set of labels, which usually carry a trace identifier. The idea is to connect a metric to a trace. A bucket that counts slow requests can point to one slow request that you can open in a tracing system.

In the OpenMetrics text format an exemplar follows the sample after a `#` character:

```text
lab_job_duration_seconds_bucket{le="0.5"} 900 # {trace_id="abc123"} 0.43
```

The part after `#` is a label set, then the value of the observation. Exemplars are allowed on counter totals and on histogram buckets. The label names and values of one exemplar may not exceed 128 UTF-8 characters in total. The scraper may drop them.

Exemplars exist only in OpenMetrics. A target that answers in the classic format cannot carry them, so exemplars need a negotiated OpenMetrics scrape. Prometheus also stores them only when you start it with the feature flag `--enable-feature=exemplar-storage`. Without the flag, Prometheus parses and ignores them. This is a concept to know for the exam: the format carries them, but the server must opt in to keep them.

## Native histograms

A classic histogram has a fixed set of buckets, and every bucket is a separate time series. If you choose the bounds badly, the quantile estimate is poor. If you add many buckets, you add many series. A native histogram is a newer type that stores the whole histogram as one series. It uses buckets with an exponential layout, so that the bounds cover a wide range of values with a fixed relative accuracy, and the application does not choose the bounds.

The consequences are:

- One series holds the distribution, so there are far fewer series for the same accuracy.
- The sum and the count are part of the same sample.
- Histograms with different resolutions can be combined by Prometheus.
- You query the histogram with the same function name, `histogram_quantile`, and with additional functions for native histograms.

Native histograms are not written in the text format. A client library sends them in the Protocol Buffers format, and for a scrape to receive them, Prometheus must negotiate `PrometheusProto`. In Prometheus v3.x this requires that scraping native histograms is enabled in the configuration. When it is on, `PrometheusProto` is put at the front of the default `scrape_protocols` list.

For this course you need to know what a native histogram is, why it needs a binary format, and that it is a different mechanism than the classic `_bucket` lines. The classic histogram remains the type that every exporter supports.

## Which format carries what

A short table helps to keep the cases apart.

| Feature | Classic text | OpenMetrics text | Protocol Buffers |
| --- | --- | --- | --- |
| Classic histogram lines | Yes | Yes | Yes |
| End marker `# EOF` | No | Required | Not applicable |
| `_created` samples | No | Optional | Not applicable |
| Exemplars | No | Yes | Yes |
| Native histograms | No | No | Yes |

The table shows why a format is chosen by negotiation. A target that has a feature can use it only when Prometheus accepts a format that carries it.

## What you know now

You know that a complete histogram needs the `+Inf` bucket with the value of `_count` and that Prometheus does not check it while parsing. When the bucket is missing, `histogram_quantile` returns `NaN`. You know that an exemplar attaches an example observation, usually with a trace identifier, to a sample, that only OpenMetrics carries it and that Prometheus needs `--enable-feature=exemplar-storage` to keep it. You know that a native histogram is one series with exponential buckets that needs the binary format. What is still open is how an application produces these pages, how a short-lived job delivers its data, and how to read the error of a failed scrape.

## Common pitfalls

> [!WARNING]
> - Assuming that a healthy target means a healthy histogram. A histogram without `le="+Inf"` is ingested and gives `NaN` quantiles.
> - Writing bucket values that decrease. They are cumulative.
> - Expecting exemplars in a classic text scrape. They exist only in OpenMetrics.
> - Expecting Prometheus to store exemplars without the feature flag `exemplar-storage`.
> - Looking for native histograms in the text of a page. They travel in the binary format.
