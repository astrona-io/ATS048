---
estimated_duration: 25m
---

# Lab: Rewrite Labels And Drop A Metric With Relabeling

Graded lab. **UNTESTED:** this lab was written and statically checked (`astrona validate`, `bash -n`) but never booted. Expect small corrections on the first live run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-020/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-020/module-02/labs/lab-01
astrona destroy ats-048-lab-020-02-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-instance-relabeled.sh` | The probe target has instance="probe-main" and is up |
| `validate-tier-label-added.sh` | Every probe series has tier="backend" |
| `validate-queue-depth-dropped.sh` | lab_queue_depth is not stored, and all other probe series still are |
