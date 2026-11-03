---
draft: true
exam_objectives:
- System Architecture
---
# Alerting And Extension Architecture

Collecting and querying metrics is only half of monitoring. Someone has to be told when a metric shows a problem, and the data often has to leave the single Prometheus server: to a longer-lived store, to a higher-level Prometheus, or from jobs that are too short to be scraped. This module covers both. It explains how alerting is split between the Prometheus server, which decides that an alert is active, and Alertmanager, which decides who is notified and how. Then it covers the extension components around the server: Pushgateway, remote write and remote read, federation and service discovery.

The module uses the same example as the rest of the course. A `probe` application in the namespace `starfleet` serves requests, a traffic generator makes about one in ten fail, and a Prometheus server scrapes the application every two seconds. In this module the playground also runs Alertmanager, which forwards notifications to a webhook receiver.

## Learning Goals

After this module you can:

- Write an alerting rule with `expr`, `for`, `labels` and `annotations`, and explain the states inactive, pending and firing.
- Describe how Prometheus sends alerts to Alertmanager and why a list of Alertmanager addresses is used.
- Explain grouping, routing, silences and inhibition in Alertmanager, and say which one stops a notification in a given case.
- Follow an alert from rule evaluation to a delivered webhook, and name the component that failed when delivery stops.
- State what Pushgateway, remote write, remote read and federation are for, and when each one is the wrong choice.
- Name the service discovery roles of Kubernetes and say what a target is for each of them.

## What To Know First

You should know how a scrape works, what a PromQL expression and a recording rule are, and how to apply a ConfigMap with `kubectl`. The playground has Prometheus v3.5.5, Alertmanager and the example application running. `kubectl` points at its cluster.

## Reading Order

1. The first part covers alerting rules: how the rule manager evaluates them, what pending and firing mean and how the `for` duration works.
2. The second part covers Alertmanager: the route tree, grouping, silences, inhibition and the connection from Prometheus. A graded lab follows this part.
3. The third part covers the extension architecture: Pushgateway, remote write and read, federation and service discovery roles.
4. The summary closes the module.

Launch your playground now and keep it running next to you while you read:

<!-- astrona:playground -->
