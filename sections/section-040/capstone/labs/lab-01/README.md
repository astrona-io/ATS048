---
estimated_duration: 45m
---

# Lab: Record Rate, Aggregation And Percentile Series

Graded lab. **UNTESTED:** this lab was written and statically checked (`astrona validate`, `bash -n`) but never booted. Expect small corrections on the first live run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-040/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-040/capstone/labs/lab-01
astrona destroy ats-048-capstone-040
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-rules-healthy.sh` | All four recording rules are loaded from the rules file and healthy |
| `validate-request-rates.sh` | job:lab_requests:rate1m has only the job label, and lab:requests_failed:rate1m has no labels and is positive |
| `validate-path-sum.sh` | path:lab_http_requests:sum has one series for each of the three paths, with only the path label |
| `validate-latency-p90.sh` | lab:request_duration_seconds:p90 is a latency in seconds from the histogram buckets |
