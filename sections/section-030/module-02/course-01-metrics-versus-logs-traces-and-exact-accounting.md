---
draft: true
exam_objectives:
- Understanding Prometheus Limitations
---
# Metrics Versus Logs, Traces, Events And Exact Accounting

A tool is only as good as the question you ask it. Prometheus stores numbers that describe a system over time, and it keeps them cheap by throwing away detail on purpose. This lesson explains what that detail is, why the loss is a design decision and what kinds of questions fall outside it. It then looks at a second, smaller loss: even the numbers that Prometheus keeps are approximate in two ways, because scrapes are periodic and because rate functions estimate.

## One request, three records

Take one request to the `probe` application. The application can leave three kinds of record about it, and each answers a different question.

A log line is a text record of one event. The `probe` writes one JSON line for every request, with a request identifier, the status code and the duration. A log answers: what happened to this request? Its size grows with the number of events.

A trace is the path of one request across several services, with the time spent in each step. A trace answers: where did the time go for this request? Its size also grows with the number of requests, so systems keep only a sample of traces.

A metric is a number that summarises many events. The `probe` exposes the counter `lab_requests_total` with the label `status`. Every request adds one to the counter for its status code. A metric answers: how many requests failed in the last five minutes? Its size depends on the number of series, not on the number of requests. Ten requests and ten million requests per second cost the same storage for this counter.

That last fact is the reason for the limit. Prometheus can store months of data cheaply because each series holds one number per scrape interval, and the number is a total, not a list of events.

<!-- astrona:playground:renew -->

See the difference in the playground. Read the log lines of the probe:

```sh
kubectl -n starfleet logs deployment/probe --tail=3
```

Each line is one request with its own `request_id`. Now read the metric of the same traffic from the metrics page of the application:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- http://probe:8080/metrics
```

Look at the lines that start with `lab_requests_total`. There is one line per status code, and the value is the count since the process started. The metric has no request identifier, and no single request can be found in it. If you must answer "what happened to request X", the metric cannot help you, and nothing you do to the query changes that.

## Why labels are not a way around it

A frequent attempt is to add the request identifier, the user or the trace id as a label, so that Prometheus can answer per-request questions. This breaks the model. Every distinct value creates a new time series, and each series costs memory in the head block. A label with a new value for every request makes millions of series that each hold one sample. The server runs out of memory long before it becomes a log store. Remember the rule: a label must have a small, bounded set of values, and per-event data belongs in a log, a trace or an event store.

## Events and state changes

An event is something that happened at a time, such as a deployment, a login or an order. Prometheus has no event type. You can count events with a counter, and you can store a changing state in a gauge, but you cannot store the content of an event. Metrics do not tell you who deployed or which order failed. A counter of deployments tells you how many happened, and a log or an event store tells you which one.

## Exact accounting

Many teams ask whether they can bill customers from a Prometheus counter. The answer is no, for four reasons that come from how the data is collected.

- Prometheus collects a counter at scrape time, every 15 seconds in a common setup. It sees the value at those moments and nothing between them. The counter value at each scrape includes all events up to then, so a counter does not lose events, but the series has no information about when between two scrapes an event happened.
- A scrape can fail. A missing scrape leaves a gap in the series. The next successful scrape contains the total again, so the sum is recovered for a counter, but a gauge value that changed inside the gap is lost.
- A process restart resets a counter to zero. The query functions detect the reset and compensate, but the compensation is an assumption: if the counter went from 90 to 5, the function assumes it restarted and counted from zero, so the events between the last scrape and the restart are lost.
- The data is not durable and not replicated by default. A lost disk loses the history, and two servers in a high availability pair hold similar but not identical values.

Billing and legal accounting need every event written once, with a durable identifier, in a store with transactions. That is a database or an event log. Prometheus is the right place for questions such as "is the error rate above the agreed level", where a small error in the number does not change the answer.

## Rate and increase are estimates

The functions `rate()` and `increase()` turn a counter into a speed or a growth over a time window. Both estimate their result, in a way you can predict. The range selector, for example `lab_requests_total[1m]`, selects the samples that lie inside the last minute. Those samples rarely start exactly at the start of the window and end exactly at its end. Prometheus therefore looks at the first and the last sample in the window and extrapolates the line to the edges of the window.

The consequence is visible: `increase()` of a counter that only grows in whole numbers can return a number with decimals. The counter went from 100 to 104 in the window, and the function may return 4.37, because it extended the slope to the full window. Over a longer period the error becomes small relative to the total, but over a short window it does not. A range that holds fewer than two samples gives no result at all, so the window must be at least a few scrape intervals long. The common advice is a window of at least four times the scrape interval.

Run the functions on the probe counter. The traffic generator sends requests all the time, so the data is available after a minute:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=increase(lab_requests_total%5B1m%5D)'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=rate(lab_requests_total%5B1m%5D)'
```

Compare the values for the `status` label that has the larger traffic. The `increase` value is close to the `rate` value multiplied by 60. Look at the decimals in the `increase` result: a counter that grows in whole numbers produced a fractional result, and that is the extrapolation at work. Then ask for the raw counter values with a range query and count the actual difference between the first and last sample. The numbers are close but not equal.

## When the estimate is good enough

The estimate is good enough for rates in dashboards and alerts, where the goal is to see a trend or to cross a threshold. It is not good enough where the exact count matters. Check the question you want to answer. If the answer must be the exact number of events, use a store that records the events. If the answer is "has the error rate gone above one percent", a metric is the right tool.

## Choosing the right store

A short list helps to match the question to the tool:

- "How many requests per second fail right now?" needs a metric, so use Prometheus.
- "Why did request X fail?" needs a log line, so use a log store.
- "Which service made request X slow?" needs a trace, so use a tracing system.
- "Who changed the configuration at 10:12?" needs an event or audit record.
- "How much must we invoice customer Y?" needs a transactional database.

The tools also work together. An alert from Prometheus tells you that something is wrong, and the logs and traces tell you which requests and which step went wrong. This is a division of work, and each tool is cheap because it does not try to do the work of the others.

You now know what Prometheus keeps, what it deliberately drops and why a counter and its rate are estimates. The next question is about the path that data takes into the server, because the pull model and the way Prometheus treats missing data create more gaps.

## Common pitfalls

> [!WARNING]
> - Do not put a request id, user id or trace id in a label to find single events. That creates one series per event and exhausts memory.
> - Do not use a Prometheus counter for billing or any figure that must be exact to the single event.
> - Do not read the decimals of an `increase()` result as an error in your counter. They come from extrapolation to the window edges.
> - Do not use a range window shorter than two scrape intervals. The query then has too few samples and returns nothing or a poor estimate.
