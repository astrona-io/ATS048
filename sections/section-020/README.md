---
draft: true
exam_objectives:
- Configuration and Scraping
---
# Configuration and Scraping

This section covers how a Prometheus server is configured to find targets, collect their metrics and shape the labels that it stores. The first module reads the configuration file from the top: the global defaults, the scrape jobs, intervals and timeouts, the labels `job` and `instance`, the `up` and `scrape_*` series, and how to validate and reload a file. The second module covers service discovery and relabeling: static and file-based discovery, the rules in `relabel_configs` and `metric_relabel_configs`, their actions, the internal labels, and `honor_labels`.

Read the module goals, the teaching parts and the closing summary in order. Each module has a playground for free exploration and one graded lab. A capstone lab at the end repairs scrape jobs with a wrong path and a wrong port, then drops a metric and adds a label with relabeling. A knowledge check closes the section.

## Learning Outcomes

- Interpret global defaults and per-job scrape settings, and state the rule that links scrape interval and scrape timeout.
- Build the scrape URL from the scheme, the target address and the metrics path, and fix a wrong port or path.
- Explain where the `job` and `instance` labels come from, how target group labels reach every series and how `honor_labels` decides a label conflict.
- Diagnose a failed scrape with `up`, the `scrape_*` series and the targets API without equating it with application downtime.
- Validate a configuration with `promtool check config` and make a running server load it with SIGHUP or a POST to `/-/reload`.
- Describe static and file-based service discovery and the labels that a discovered target has before relabeling.
- Write `relabel_configs` and `metric_relabel_configs` rules with the actions `replace`, `keep`, `drop`, `labelmap` and `labeldrop`, and choose the right list for a task.
