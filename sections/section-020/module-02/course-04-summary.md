---
draft: true
exam_objectives:
- Configuration and Scraping
---
# Summary

Service discovery produces the targets of a scrape job. The simplest methods are `static_configs`, where the file lists the targets, and `file_sd_configs`, where Prometheus reads target groups from YAML or JSON files and follows changes without a reload of the main configuration. Other mechanisms, such as Kubernetes or DNS discovery, produce the same result: targets with labels.

Every discovered target has a label set before relabeling. It contains the internal labels `__address__`, `__scheme__`, `__metrics_path__` and `__param_<name>`, the job name, labels from the target group and the meta labels `__meta_*` of the mechanism. Prometheus removes labels that start with two underscores after relabeling, so a rule must copy a meta label into a normal label if the value should be stored. The targets API shows the labels before and after relabeling.

The list `relabel_configs` runs once per target, before the scrape request. A rule reads the `source_labels`, joins them with the separator, matches an anchored regular expression and applies its action. The action `replace` writes the replacement into `target_label`. The actions `keep` and `drop` select targets, `labelmap` copies labels to new names and `labeldrop` removes labels by name. Writing `__address__`, `__scheme__` or `__metrics_path__` changes the request itself, while writing `instance` only changes the label.

The list `metric_relabel_configs` runs after the scrape on every sample, before storage. It sees the metric name in `__name__`, so it can drop one metric or one label while the target stays healthy. A rule in the wrong list never matches or matches the wrong data, and Prometheus gives no error for it. The series `scrape_samples_scraped` and `scrape_samples_post_metric_relabeling` show how many samples a rule removed.

The settings `metrics_path`, `params` and `scheme` set the path, the URL parameters and the scheme for a whole job. The setting `honor_labels` decides a label conflict. The default is false: the target labels win and the scraped label is renamed with the prefix `exported_`. A value of true makes the scraped label win and fits sources such as a Pushgateway.

Key facts:

- Relabel regular expressions are anchored and match the whole value.
- The default action is `replace`, the default regex is `(.*)` and the default replacement is `$1`.
- `relabel_configs` acts on targets before the scrape, `metric_relabel_configs` acts on samples after it.
- Internal labels with two underscores do not reach storage.

<!-- astrona:playground:destroy -->
