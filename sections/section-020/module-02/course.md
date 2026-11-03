---
draft: true
exam_objectives:
- Configuration and Scraping
---
# Service Discovery And Relabeling

A real environment has more targets than anyone wants to type into a file, and the labels that discovery or the application provides are rarely the labels that you want to store. Prometheus solves both problems in the scrape configuration. Service discovery finds the targets, and relabeling rewrites their labels and filters their samples.

This module teaches how targets enter a job, how a rule rewrites a label set, and the difference between rules that run before the scrape and rules that run after it.

## Learning Goals

- Describe static configuration and file-based service discovery, and say when each fits.
- Explain which labels exist before and after relabeling, and read the internal labels `__address__`, `__scheme__`, `__metrics_path__`, `__param_<name>` and `__meta_*`.
- Write `relabel_configs` rules with the actions `replace`, `keep`, `drop` and `labelmap`.
- Write `metric_relabel_configs` rules with `drop` and `labeldrop`, and state why the two lists are not interchangeable.
- Explain `honor_labels`, `metrics_path`, `params` and `scheme` for a job.

## Before You Start

You should be able to read a `prometheus.yml` file with a global section and scrape jobs, and know that every sample carries the labels `job` and `instance`. The playground runs Prometheus v3.5.5 in the namespace `starfleet` with the example application `probe` and a `shuttle` pod with `wget`. The configuration is the key `prometheus.yaml` of the ConfigMap `prometheus-config`.

## Reading Order

The first part covers how targets are found and the labels that discovery produces. The second part covers relabeling before the scrape. The third part covers relabeling after the scrape and the label conflict setting. The module ends with a summary.

<!-- astrona:playground -->
