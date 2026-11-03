---
estimated_duration: 25m
---

# Lab: Record Derived Series In A Rule File

Graded lab. **UNTESTED:** this lab was written and statically checked (`astrona validate`, `bash -n`) but never booted. Expect small corrections on the first live run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-010/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-048-lab-010-01-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-rules-loaded.sh` | Both recording rules are loaded from the rules file and evaluate without error |
| `validate-request-rate-recorded.sh` | job:lab_requests_total:rate1m exists with only the job label and a positive value |
| `validate-error-ratio-recorded.sh` | job:lab_requests_errors:ratio_rate1m exists and is close to the real error share |
| `validate-raw-series-intact.sh` | The probe target is still scraped and the raw counter is still stored |
