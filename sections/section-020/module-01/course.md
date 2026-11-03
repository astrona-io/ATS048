---
draft: true
exam_objectives:
- Configuration and Scraping
---
# The Prometheus Configuration File

Every Prometheus server starts from one configuration file, usually called `prometheus.yml`. The file tells the server how often to collect data, which targets to collect it from, which rule files to load and which labels to attach. A mistake in this file is the most common reason why a graph is empty, so reading it fluently is a core skill for the exam and for daily work.

This module explains the file from the top down and ties each setting to something you can observe in a running server.

## Learning Goals

- Describe the `global` section and the `scrape_configs` list, and explain how a job value overrides a global value.
- Explain how the scrape URL is built from the scheme, the target address and the metrics path.
- Distinguish `scrape_interval`, `scrape_timeout` and `evaluation_interval`, and state the rule that links interval and timeout.
- Explain where the `job` and `instance` labels come from, and how labels on a target group reach every series.
- Read the `up` series and the `scrape_*` series to decide why a scrape fails.
- Validate a file with `promtool check config` and make a running server load a changed file.

## Before You Start

You should know what a metric, a label and a scrape are, and you should be able to read basic YAML. The playground for this module runs Prometheus v3.5.5 in the namespace `starfleet`, together with the example application `probe` and a traffic generator that calls it. The configuration lives in the Kubernetes ConfigMap `prometheus-config`. A `shuttle` pod gives you a shell with `wget` inside the cluster network.

## Reading Order

The first part reads the structure of the file and the timing settings. The second part follows labels and the automatic series that Prometheus records for every scrape. The third part validates a file and loads it into a running server. The module ends with a summary.

<!-- astrona:playground -->
