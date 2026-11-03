---
estimated_duration: 25m
---

# Lab: Aggregate A High-Cardinality Label And Select With Matchers

Graded lab. **UNTESTED:** this lab was written and statically checked (`astrona validate`, `bash -n`) but never booted. Expect small corrections on the first live run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-040/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-040/module-02/labs/lab-01
astrona destroy ats-048-lab-040-02-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-path-totals.sh` | path:lab_http_requests_total:sum has one series per path with the request id removed |
| `validate-path-series-count.sh` | path:lab_http_requests_total:series counts the series behind each path |
| `validate-shop-selector.sh` | lab:shop_requests:sum adds only the /orders and /cart paths |
| `validate-rules-healthy.sh` | All three rules are loaded from the rules file and healthy |
