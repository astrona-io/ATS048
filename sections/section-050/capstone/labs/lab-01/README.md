---
estimated_duration: 45m
---

# Lab: Repair A Page With Counters, Gauges And A Histogram

Graded lab. **UNTESTED:** this lab was written and statically checked (`astrona validate`, `bash -n`) but never booted. Expect small corrections on the first live run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-050/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-050/capstone/labs/lab-01
astrona destroy ats-048-capstone-050
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-exporter-scrape-ok.sh` | The exporter target is up, so the whole page parses |
| `validate-counter-and-gauge.sh` | The counter has ok=1027 and error=13, and lab_workers is 4 |
| `validate-histogram-complete.sh` | The +Inf bucket and the _count series both equal 1040 |
| `validate-histogram-types.sh` | The metadata API reports counter, gauge and histogram for the three families |
