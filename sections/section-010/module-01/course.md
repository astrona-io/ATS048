---
draft: true
exam_objectives:
- System Architecture
---
# The Prometheus Collection, Storage And Query Pipeline

Prometheus is a monitoring system that collects numeric measurements from running software, stores them as time series on its own disk, and answers questions about them with a query language. Every sample you see on a graph has travelled the same path: an application or exporter exposes it, the Prometheus server scrapes it, the local time series database stores it, and a query or a rule reads it back. When a graph is empty or a number looks wrong, you must know which stage failed. This module teaches the stages one by one.

The module is built around one example. A small application named `probe` exposes request counters on `/metrics`. A traffic generator sends requests to it, and about one in ten of them fails with status 500. A Prometheus server in the `starfleet` namespace scrapes `probe` every two seconds. You follow the samples from the application to a stored series, then to a query result, and finally to a recording rule that stores a derived result under a new name.

## Learning Goals

After this module you can:

- Name the components of the Prometheus server and say what each one does: scrape manager, time series database, query engine, rule manager and web server.
- Explain how a scrape works, why Prometheus pulls, and what an exporter is for.
- Read the `up` series and the `scrape_*` series to judge the health of a target.
- Describe how samples move from the head block and the write-ahead log into persisted blocks.
- Run an instant query and a range query through the HTTP API and read the JSON envelope.
- Write a recording rule, name it with the `level:metric:operations` convention, and make the server load it.

## What To Know First

You should know what a metric, a label and a counter are in everyday terms, and be able to read short YAML files. You should be able to run `kubectl get` and `kubectl apply`. No earlier Prometheus experience is needed. The playground already runs the server, the application and the traffic, and `kubectl` points at its cluster.

## Reading Order

1. The first part follows one scrape from the exposed text to a stored sample and explains the components of the server, the pull model and exporters.
2. The second part opens the time series database and the query engine and shows how the HTTP API returns instant and range query results.
3. The third part covers recording rules: how the rule manager evaluates them, how to name them and how to load a changed rule file. A graded lab follows this part.
4. The summary closes the module.

Launch your playground now and keep it running next to you while you read:

<!-- astrona:playground -->
