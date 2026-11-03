---
draft: true
exam_objectives:
- Configuration and Scraping
---
# Summary

The Prometheus configuration file has a small set of top-level keys. The `global` section holds default values, `rule_files` names the rule files and `scrape_configs` lists the scrape jobs. Each job describes a group of targets that Prometheus scrapes in the same way, and it can override the global scrape interval and scrape timeout for itself. The timeout must never be longer than the interval, and `evaluation_interval` is a separate clock that controls rules, not scraping.

Prometheus builds the scrape URL from the scheme, the address in `targets` and the metrics path. The defaults are `http` and `/metrics`. A wrong port produces a connection error and a wrong path produces an HTTP 404 answer, so the last error of a target tells you which setting to repair.

Every scraped sample gets the label `job` from the job name and the label `instance` from the target address. Labels written on a target group are attached to all targets of the group and appear on every series, including the automatic ones. When a scraped label has the same name as a target label, Prometheus renames the scraped one with the prefix `exported_`, unless `honor_labels` is true.

For every scrape, Prometheus records the series `up` and the `scrape_*` series. The value of `up` is 1 for a successful scrape and 0 for a failed one. It describes the scrape and not the application. A failed scrape comes from a refused connection, a timeout, a bad HTTP status or an unreadable body.

The tool `promtool check config` validates a file before it is loaded. It finds syntax errors and invalid values, and it cannot know whether a target is reachable. Prometheus reloads its configuration on SIGHUP or on a POST request to `/-/reload` when the lifecycle endpoint is enabled. An invalid file leaves the old configuration in force, and the metric `prometheus_config_last_reload_successful` shows whether the last reload worked.

Key facts:

- Default `scrape_interval` is one minute, default `scrape_timeout` is ten seconds, and the timeout cannot exceed the interval.
- A job value overrides a global value for that job only.
- `up` is 1 or 0, and 0 does not prove that the application is down.
- Reload needs SIGHUP or POST `/-/reload`, and a failed reload keeps the old file in force.

<!-- astrona:playground:destroy -->
