---
estimated_duration: 25m
---

# Lab: Repair And Tune A Scrape Job

Graded lab. **UNTESTED:** this lab was written and statically checked (`astrona validate`, `bash -n`) but never booted. Expect small corrections on the first live run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-020/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-020/module-01/labs/lab-01
astrona destroy ats-048-lab-020-01-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-probe-target-up.sh` | The probe job scrapes the application and up is 1 |
| `validate-probe-scrape-timing.sh` | The probe job has scrape_interval 5s and scrape_timeout 3s |
| `validate-probe-env-label.sh` | Every probe series carries env="lab" from the target group |
| `validate-self-scrape-kept.sh` | The prometheus job still scrapes the Prometheus server and keeps the global interval |
