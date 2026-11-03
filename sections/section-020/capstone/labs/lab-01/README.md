---
estimated_duration: 45m
---

# Lab: Repair Scrape Jobs And Shape The Stored Series

Graded lab. **UNTESTED:** this lab was written and statically checked (`astrona validate`, `bash -n`) but never booted. Expect small corrections on the first live run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-020/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-020/capstone/labs/lab-01
astrona destroy ats-048-capstone-020
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-probe-up.sh` | The probe target is up |
| `validate-exporter-up.sh` | The exporter target is up |
| `validate-queue-length-dropped.sh` | lab_queue_length is not stored, while the other exporter metrics are |
| `validate-env-label.sh` | Every exporter series has the label env=training |
