---
estimated_duration: 45m
---

# Lab: Bound The Server Storage And A Crowded Target

Graded lab. **UNTESTED:** this lab was written and statically checked (`astrona validate`, `bash -n`) but never booted. Expect small corrections on the first live run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-030/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-030/capstone/labs/lab-01
astrona destroy ats-048-capstone-030
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-retention-flags.sh` | The server keeps data for 12h and caps blocks at 1GB |
| `validate-crowded-limit-config.sh` | The job crowded has a sample_limit between 1 and 199 |
| `validate-crowded-rejected.sh` | The crowded target is down with a sample limit error and none of its series are stored |
| `validate-server-healthy.sh` | Prometheus is ready, the probe target is up and the existing flags remain |
