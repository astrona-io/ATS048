---
estimated_duration: 25m
---

# Lab: Repair An Invalid Text Exposition Page

Graded lab. **UNTESTED:** this lab was written and statically checked (`astrona validate`, `bash -n`) but never booted. Expect small corrections on the first live run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-050/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-050/module-01/labs/lab-01
astrona destroy ats-048-lab-050-01-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-exporter-scrape-ok.sh` | The exporter target is up, so Prometheus parsed the whole page |
| `validate-counter-series.sh` | lab_jobs_processed_total has the series ok=1027 and error=13 with the label queue=default |
| `validate-gauge-values.sh` | lab_workers is 4 and lab_queue_length is 7 |
| `validate-types-declared.sh` | The metadata API reports counter for lab_jobs_processed_total and gauge for the other two |
