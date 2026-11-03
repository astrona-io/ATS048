---
estimated_duration: 25m
---

# Lab: Choose The Right Query For Each Metric Type

Graded lab. **UNTESTED:** this lab was written and statically checked (`astrona validate`, `bash -n`) but never booted. Expect small corrections on the first live run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-040/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-040/module-01/labs/lab-01
astrona destroy ats-048-lab-040-01-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-counter-rate-by-status.sh` | status:lab_requests:rate1m has one series per status value and no other labels |
| `validate-histogram-quantile.sh` | lab:request_duration_seconds:p95 is a latency in seconds from the histogram buckets |
| `validate-gauge-max.sh` | lab:queue_depth:max is the highest current queue depth |
| `validate-rules-healthy.sh` | All three rules are loaded from the rules file and healthy |
