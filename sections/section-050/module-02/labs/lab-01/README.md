---
estimated_duration: 25m
---

# Lab: Fix An OpenMetrics Page With A Histogram

Graded lab. **UNTESTED:** this lab was written and statically checked (`astrona validate`, `bash -n`) but never booted. Expect small corrections on the first live run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-050/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-050/module-02/labs/lab-01
astrona destroy ats-048-lab-050-02-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-openmetrics-scrape-ok.sh` | The exporter target is up when Prometheus negotiates OpenMetrics |
| `validate-counter-total-series.sh` | lab_jobs_failed_total has reason=timeout 5 and reason=oom 2 |
| `validate-histogram-complete.sh` | The histogram has a +Inf bucket equal to the count, so histogram_quantile returns a number |
| `validate-histogram-quantile-number.sh` | histogram_quantile(0.9, ...) over the buckets returns a finite value |
