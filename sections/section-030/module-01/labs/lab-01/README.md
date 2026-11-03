---
estimated_duration: 25m
---

# Lab: Set Retention And Query Limits On The Server

Graded lab. **UNTESTED:** this lab was written and statically checked (`astrona validate`, `bash -n`) but never booted. Expect small corrections on the first live run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-030/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-030/module-01/labs/lab-01
astrona destroy ats-048-lab-030-01-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-retention-time.sh` | The server keeps data for 6 hours (--storage.tsdb.retention.time=6h) |
| `validate-retention-size.sh` | The server caps block storage at 500MB (--storage.tsdb.retention.size=500MB) |
| `validate-query-limits.sh` | Queries time out after 30s and may load 10000000 samples |
| `validate-server-healthy.sh` | Prometheus is ready and still scrapes the probe target |
