---
draft: true
exam_objectives:
- Exposition Format
---
# Lines, Families And Labels In The Text Format

Every Prometheus target, whether it is an application with a client library or a separate exporter, answers one HTTP request with a plain text page. Prometheus parses that page line by line and turns each sample line into a time series sample. If you can read the page, you can tell what the target measures and why Prometheus accepted or rejected it. This lesson takes the format apart, starting with a real page, then moving to the rules.

## Look at a real page first

The `probe` application in the playground serves its metrics on port 8080. The `shuttle` pod has `wget`, so you can request the page from inside the cluster. The playground renews its timer when you start working, so the environment stays available while you read the output.

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://probe:8080/metrics
```

The answer is a list of lines. Some start with `# HELP` or `# TYPE`. The other lines hold a metric name, optional labels in curly braces, and a number. You will see counters such as `lab_requests_total`, gauges such as `lab_queue_depth` and a histogram for the request duration. The exact numbers change with traffic, so look at the structure and not at the values.

## The line-oriented layout

The text format is line-oriented. A line feed character (`\n`) ends each line, and empty lines are ignored. Tokens on a line are separated by blanks or tabs, and leading and trailing white space is ignored. A line that starts with `#` is a comment, unless its first token after the `#` is `HELP` or `TYPE`. Prometheus skips ordinary comments.

Because the parser works line by line, a single bad line is enough to make the whole scrape fail. Prometheus does not skip the bad line and keep the good ones. This is the reason why a small typo in one metric can make every metric of the target disappear from one scrape onward.

## Metric families and metadata lines

All lines that belong to one metric are written as one group, called a metric family. The group starts with the metadata lines and then holds the samples. A metadata line has one of two forms.

```text
# HELP lab_workers Number of running workers.
# TYPE lab_workers gauge
lab_workers 4
```

The `# HELP` line gives the metric name and a short description. The `# TYPE` line gives the metric name and its type, which is one of `counter`, `gauge`, `histogram`, `summary` or `untyped`. Rules for these lines are strict:

- A metric has at most one `# HELP` line and at most one `# TYPE` line.
- The `# TYPE` line must come before the first sample of that metric name.
- All lines of one metric must be together. You cannot write a sample of `lab_workers`, then another metric, then another sample of `lab_workers`.
- If there is no `# TYPE` line, the type is `untyped`.

Prometheus uses the metadata for the metadata API and for the user interface, and it helps people read the page. It does not change how the samples are stored, because the stored data is a series of timestamps and float values. The type tells people and tools how to use the metric: a counter is used with `rate`, and a gauge is read as it is.

## Sample lines

A sample line has three parts: the metric name, an optional set of labels, and a value. An optional timestamp may follow the value.

```text
lab_jobs_processed_total{queue="default",result="ok"} 1027
```

Here `lab_jobs_processed_total` is the metric name, `queue` and `result` are label names, `"default"` and `"ok"` are label values, and `1027` is the value. A metric name matches the pattern `[a-zA-Z_:][a-zA-Z0-9_:]*`. This means a name can contain letters, digits, underscores and colons, and it cannot start with a digit. A hyphen is not allowed, so `lab-queue-length` is invalid. Label names match `[a-zA-Z_][a-zA-Z0-9_]*`, which is the same without the colon.

Each combination of metric name and label set must appear only once on a page. If two lines have the same name and the same labels, the result of the ingestion is undefined.

## Label values and escaping

A label value is always written inside double quotes. Writing `queue=default` without the quotes is a parse error. The value is a string in UTF-8, so it can hold any text, but three characters need an escape so that the line stays valid:

- A backslash is written as `\\`.
- A double quote is written as `\"`.
- A line feed is written as `\n`.

For example, a label for a Windows path and a quoted word is written like this.

```text
lab_files_total{path="C:\\data",note="said \"stop\""} 2
```

In a `# HELP` text, a backslash and a line feed must also be escaped as `\\` and `\n`, but a double quote does not need an escape there, because the text is not in quotes. If you write a raw line feed inside a label value, the page splits into two lines, and the second half is not a valid line.

Client libraries do this escaping for you. The risk appears when people write the page by hand, or build it with string formatting in a custom exporter and put user text into a label value.

## Values

The value is a float. Prometheus reads it as the Go function `ParseFloat` does, so `1027`, `0.5`, `1e3` and `-3.2` are all valid. Three special words are also valid: `NaN`, `+Inf` and `-Inf`. Any other word is invalid. The line `lab_workers four` fails to parse, because `four` is not a number.

The value of every sample is a 64-bit float. This is why a counter that counts jobs is written as `1027` and not as `1027 jobs`: the unit belongs in the metric name, for example `_seconds` or `_bytes`.

## Timestamps

A sample line may end with a timestamp. It is an integer number of milliseconds since the Unix epoch.

```text
lab_workers 4 1730000000000
```

Most targets do not write timestamps, and this is the normal case. When the timestamp is missing, Prometheus uses the time of the scrape as the time of the sample. This is correct for almost every target, because the value was read at the moment of the request.

A timestamp makes Prometheus store the sample at that time instead. It is used in special cases, for example when an exporter republishes a value that was measured earlier by another system. The cost is that Prometheus does not mark a series as stale in the same way when it disappears from the page, and old or repeated timestamps can lead to rejected samples. The advice for application authors is to leave the timestamp out.

## Worked example: find the faults

Look at this page and decide which lines break the rules before you read the answer.

```text
# TYPE lab_workers gauge
lab_workers four
# TYPE lab_workers gauge
lab-queue-length 7
lab_jobs_total{queue=default} 3
```

There are four faults. The value `four` is not a float. The second `# TYPE lab_workers` line repeats a type line. The name `lab-queue-length` has hyphens. The label value `default` has no quotes. Prometheus stops at the first fault it meets and reports its line number, so you fix the faults one at a time and scrape again.

## Try the parser yourself

The playground has an `exporter` Deployment that serves a page from the ConfigMap `exporter-metrics`. Request the page as Prometheus sees it:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://exporter:8080/metrics
```

In the playground the page is valid. Check that Prometheus parsed it by asking for the `up` series of the job `exporter`:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=up{job="exporter"}'
```

The result holds one series with the value `1`, which means the last scrape succeeded. The next lesson uses the histogram on the same page to see how several lines make one metric.

## What you know now

You can read a metrics page as a list of metric families. Each family has an optional `# HELP` line, an optional `# TYPE` line and one or more sample lines. A sample line holds a valid name, quoted and escaped label values, a float value and sometimes a millisecond timestamp. One invalid line fails the whole scrape. What is still open is how a type with several values, a histogram or a summary, is spread over many lines.

## Common pitfalls

> [!WARNING]
> - Writing a label value without double quotes, such as `queue=default`. The whole page fails to parse.
> - Putting hyphens or dots in a metric name. Only letters, digits, underscores and colons are valid.
> - Writing the `# TYPE` line after the first sample of the metric, or writing it twice.
> - Splitting the lines of one metric into two places on the page.
> - Writing a unit or a word after the number. The value must be a plain float.
> - Adding timestamps to samples out of habit. Without a reason, leave them out.
