---
draft: true
exam_objectives:
- System Architecture
---
# System Architecture

This section teaches how the parts of a Prometheus system fit together and which part is responsible for each step, from the exposed metric to a delivered notification. It has two modules and a capstone. The first module follows samples through collection, storage and query. The second module covers alerting and the components around the server.

Each module has a playground without grading and a graded lab. The reading comes first, the graded task follows the part it practises, and the capstone combines both modules at the end. A knowledge check closes the section.

## Learning Outcomes

- Name the components of the Prometheus server and say what each one does.
- Trace a sample from an exposed endpoint through a scrape into the time series database.
- Explain the head block, the write-ahead log, persisted blocks and retention.
- Run instant and range queries through the HTTP API and read the result.
- Write recording rules, name them with the `level:metric:operations` convention and make the server load them.
- Write alerting rules and explain the states inactive, pending and firing.
- Connect Prometheus to Alertmanager and explain grouping, routing, silences and inhibition.
- Say what the Pushgateway, remote write, remote read and federation are for, and when not to use them.
- Name the Kubernetes service discovery roles and what a target is for each.
- Find which stage of the pipeline failed when a graph is empty or a notification does not arrive.
