# Prometheus Fundamentals (ATS048)

Prometheus Certified Associate (PCA): Prometheus Fundamentals, worth 20% of the official curriculum. This course belongs to ATP010.

Each of the five sections has two modules. A module has a landing page, three lesson parts, a summary, a playground and a graded lab. Each section ends with a capstone lab and a quiz, and a final domain quiz closes the course. Technical content remains draft and every lab is untested.

## Course Outline

| Section | Official objective | Modules |
| --- | --- | --- |
| 010 | System Architecture | 2 |
| 020 | Configuration and Scraping | 2 |
| 030 | Understanding Prometheus Limitations | 2 |
| 040 | Data Model and Labels | 2 |
| 050 | Exposition Format | 2 |

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

## Author Review

See [curriculum coverage](CURRICULUM.md), [primary sources](SOURCES.md), [question-bank documentation](ASSESSMENTS.md) and [contribution instructions](CONTRIBUTING.md). No runtime execution is claimed.
