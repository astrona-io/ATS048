# Curriculum Coverage

Exam: Prometheus Certified Associate (PCA). Domain: Prometheus Fundamentals (20%).

The [official objectives](https://training.linuxfoundation.org/certification/prometheus-certified-associate/) were checked on 2026-10-11. Teaching structure is independently authored and does not add official requirements.

| Section | Official objective | Modules | Capstone |
| --- | --- | --- | --- |
| 010 | System Architecture | 2 | Repair Alerting From Rule To Webhook |
| 020 | Configuration and Scraping | 2 | Repair Scrape Jobs And Shape The Stored Series |
| 030 | Understanding Prometheus Limitations | 2 | Bound The Server Storage And A Crowded Target |
| 040 | Data Model and Labels | 2 | Record Rate, Aggregation And Percentile Series |
| 050 | Exposition Format | 2 | Repair A Page With Counters, Gauges And A Histogram |

| Section / module | Module | Graded lab |
| --- | --- | --- |
| 010 / 01 | The Prometheus Collection, Storage And Query Pipeline | Record Derived Series In A Rule File |
| 010 / 02 | Alerting And Extension Architecture | Fire An Alert And Reach Alertmanager |
| 020 / 01 | The Prometheus Configuration File | Repair And Tune A Scrape Job |
| 020 / 02 | Service Discovery And Relabeling | Rewrite Labels And Drop A Metric With Relabeling |
| 030 / 01 | Prometheus Storage And Scale | Set Retention And Query Limits On The Server |
| 030 / 02 | What Prometheus Is Not For | Protect The Server From A High-Cardinality Target |
| 040 / 01 | Time Series, Samples And Metric Types | Choose The Right Query For Each Metric Type |
| 040 / 02 | Label Design, Cardinality And Staleness | Aggregate A High-Cardinality Label And Select With Matchers |
| 050 / 01 | The Text Exposition Format | Repair An Invalid Text Exposition Page |
| 050 / 02 | OpenMetrics, Client Libraries And Scrape Errors | Fix An OpenMetrics Page With A Histogram |

AUTHORING.yaml records measurable goals. Every objective keeps its section ID. All technical readings remain draft. Live verification is recorded separately and is still pending.

## Hands-On Coverage

This course has 10 ungraded playgrounds (one per module), 10 graded module labs, 5 graded section capstones, 5 section quizzes and a final domain quiz. Every lab and playground is built but untested: no lab was started, booted or graded, and only static checks (`astrona validate`, `bash -n`, YAML parsing) have run.

| Section / module | Module | Graded lab |
| --- | --- | --- |
| 010 / 01 | The Prometheus Collection, Storage And Query Pipeline | Record Derived Series In A Rule File |
| 010 / 02 | Alerting And Extension Architecture | Fire An Alert And Reach Alertmanager |
| 020 / 01 | The Prometheus Configuration File | Repair And Tune A Scrape Job |
| 020 / 02 | Service Discovery And Relabeling | Rewrite Labels And Drop A Metric With Relabeling |
| 030 / 01 | Prometheus Storage And Scale | Set Retention And Query Limits On The Server |
| 030 / 02 | What Prometheus Is Not For | Protect The Server From A High-Cardinality Target |
| 040 / 01 | Time Series, Samples And Metric Types | Choose The Right Query For Each Metric Type |
| 040 / 02 | Label Design, Cardinality And Staleness | Aggregate A High-Cardinality Label And Select With Matchers |
| 050 / 01 | The Text Exposition Format | Repair An Invalid Text Exposition Page |
| 050 / 02 | OpenMetrics, Client Libraries And Scrape Errors | Fix An OpenMetrics Page With A Histogram |

| Section | Capstone lab |
| --- | --- |
| 010 | Repair Alerting From Rule To Webhook |
| 020 | Repair Scrape Jobs And Shape The Stored Series |
| 030 | Bound The Server Storage And A Crowded Target |
| 040 | Record Rate, Aggregation And Percentile Series |
| 050 | Repair A Page With Counters, Gauges And A Histogram |

