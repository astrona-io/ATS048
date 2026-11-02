---
draft: true
exam_objectives:
- System Architecture
---
# Summary

Prometheus discovers targets, scrapes exposed metrics and stores samples for queries and rule evaluation. Recording rules materialize evaluated expressions, while alert rules produce alert state for matching series.

Alertmanager manages downstream notifications rather than scraping applications. Local collection, rule evaluation and remote delivery can fail independently, so useful diagnosis follows the responsible stage and its evidence instead of one overall component label.

<!-- astrona:playground:destroy -->
