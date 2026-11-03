---
estimated_duration: 25m
---

# Lab: Protect The Server From A High-Cardinality Target

Graded lab. **UNTESTED:** this lab was written and statically checked (`astrona validate`, `bash -n`) but never booted. Expect small corrections on the first live run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-030/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-030/module-02/labs/lab-01
astrona destroy ats-048-lab-030-02-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-crowded-job-limited.sh` | The job crowded exists and has a sample_limit between 1 and 199 |
| `validate-crowded-scrape-rejected.sh` | The crowded target is down with a sample limit error |
| `validate-crowded-series-not-stored.sh` | No lab_ticket_info series from the rejected scrape is stored |
| `validate-other-targets-healthy.sh` | The probe target is still up |
