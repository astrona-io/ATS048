# Reusable Question Banks

`assessments/index.yaml` lists the banks. Each bank uses schema version 1 and the contract in `schemas/question-bank.schema.json`. The five section banks sit next to their section as `sections/section-0X0/quiz.yaml`. The final domain bank is `sections/final-domain-quiz.yaml`. All of them are registered in `astrona.yaml` as `type: quiz` entries with `pass_score: 70`.

Banks contain original single-choice questions with one correct option, an explanation on every option, a measurable learning objective and the reading paths that teach the answer. They remain draft for review.

## Fields

- `id`: stable bank or question identity; keep it when editing wording.
- `scope`: section or domain checkpoint.
- `learning_objective`: the measurable outcome checked by the question.
- `source_readings`: author traceability to the teaching.
- `prompt`: learner-visible question text.
- `options`: stable option IDs, answer text and per-option feedback.
- `correct_option`: the ID of the single correct option.
- `explanation`: feedback that reinforces the supported answer.

The banks contain answer keys and are public learning material, so this is not a secure examination bank. Scores are not an official PCA result.

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

