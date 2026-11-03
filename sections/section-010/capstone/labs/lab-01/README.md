---
estimated_duration: 45m
---

# Lab: Repair Alerting From Rule To Webhook

Graded lab. **UNTESTED:** this lab was written and statically checked (`astrona validate`, `bash -n`) but never booted. Expect small corrections on the first live run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-010/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-010/capstone/labs/lab-01
astrona destroy ats-048-capstone-010
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-alertmanager-connected.sh` | Prometheus lists alertmanager:9093 as an active Alertmanager |
| `validate-alert-fires.sh` | LabHighErrorRatio is in the firing state in Prometheus |
| `validate-alert-in-alertmanager.sh` | Alertmanager holds the alert with severity=page |
| `validate-webhook-delivered.sh` | The webhook receiver got a notification for LabHighErrorRatio |
