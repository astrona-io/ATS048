---
estimated_duration: 25m
---

# Lab: Fire An Alert And Reach Alertmanager

Graded lab. **UNTESTED:** this lab was written and statically checked (`astrona validate`, `bash -n`) but never booted. Expect small corrections on the first live run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-010/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-010/module-02/labs/lab-01
astrona destroy ats-048-lab-010-02-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-alertmanager-connected.sh` | Prometheus lists alertmanager:9093 as an active Alertmanager |
| `validate-alert-rule-defined.sh` | The alerting rule LabHighErrorRatio exists with a 10 second for duration and severity=page |
| `validate-alert-firing.sh` | LabHighErrorRatio is in the firing state in Prometheus |
| `validate-alert-delivered.sh` | Alertmanager received the alert with the label severity=page |
