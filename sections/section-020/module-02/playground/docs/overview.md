# Overview: Explore Service Discovery And Relabeling (Playground)

This is a playground, not a lab. It starts a fresh cluster with Prometheus and the example application, and then waits. There is no task, no `astrona submit` and no pass or fail. Write relabeling rules, watch what they do, run `astrona destroy` and start again.

## What is in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` points at it as the cluster administrator.
- Prometheus v3.5.5 in the namespace `starfleet`. It reads the key `prometheus.yaml` of the ConfigMap `prometheus-config`.
- The example application `probe` on port 8080. It exposes the metrics `lab_requests_total`, `lab_queue_depth`, `lab_last_success_timestamp_seconds` and the histogram `lab_request_duration_seconds`.
- A traffic generator and a pod `shuttle` with `wget`.

The starting file has two jobs: `probe` with the target `probe:8080` and the target group label `team: starfleet`, and `prometheus` with the target `localhost:9090`. The jobs have no relabeling yet.

## Helpers

Paste these once in each new terminal. `api_get` sends a GET request to the Prometheus API from the `shuttle` pod. `reload_prometheus` restarts the deployment so that it reads the current ConfigMap.

```sh
api_get() {
  kubectl -n starfleet exec shuttle -- wget -qO- "http://prometheus:9090$1"
}
reload_prometheus() {
  kubectl -n starfleet rollout restart deployment/prometheus
  kubectl -n starfleet rollout status deployment/prometheus
}
```

## Exercise 1: See the labels before and after

Run `api_get '/api/v1/targets?state=active'`. For the `probe` target, compare `discoveredLabels` and `labels`. List the labels that exist only before relabeling, and the label that exists only after. Explain where `instance` came from.

## Exercise 2: Rewrite and add labels

Edit the ConfigMap, add `relabel_configs` to the job `probe` and reload. Add two rules: one that writes the constant `backend` into `tier`, and one that writes `probe-main` into `instance`. Check the targets API again. The `scrapeUrl` must still contain `probe:8080`. Then query `up{job="probe"}` and `lab_requests_total` and read the labels of the results.

Predict before you look: which label does `up` carry for the new instance value? After the check, change the second rule so that it writes `__address__` instead of `instance`, with a wrong value such as `probe:9999`, and look at the target. Read `lastError`. Restore the correct rule.

## Exercise 3: Build a label from another label

Add a rule that copies the host part of `__address__` into a new label `host`. Use the source label `__address__`, the regex `(.*):[0-9]+` and the replacement `$1`. Check that `host` has the value `probe` on the series of the job.

Then change the regex to `probe` and reload. Predict the result, and then check: the label `host` disappears, because the regular expression is anchored and does not match `probe:8080`. A `replace` rule that does not match gives no error.

## Exercise 4: Keep and drop targets

Add a second target to the job `probe`, such as `probe:8081`, which has no listener. Check that it is down in the targets API. Then add a `drop` rule to `relabel_configs` that matches `__address__` with the regex `.*:8081`. After the reload, the target is gone from the active targets and does not appear as a failed scrape. Look at `droppedTargets` in the targets API reply.

Try the opposite with `keep` and the regex `.*:8080`. Predict which targets stay, and compare with what you see.

## Exercise 5: Drop a metric after the scrape

Add `metric_relabel_configs` to the job `probe`. Add a rule that has the source label `__name__`, the regex `lab_queue_depth` and the action `drop`. Reload and query `lab_queue_depth`: the result is empty. Fetch `http://probe:8080/metrics` with `wget` from the `shuttle` pod and confirm that the application still exposes the metric.

Compare the series `scrape_samples_scraped` and `scrape_samples_post_metric_relabeling` for the job. Their difference tells you how many samples the rule removed in one scrape.

Then move the same rule into `relabel_configs` and reload. The metric is stored again. Explain why: that list does not see metric names.

## Exercise 6: Remove a label and a conflict

Add a rule to `metric_relabel_configs` with the action `labeldrop` and the regex `team`. Check that the series of the job lose the label `team`. Then restore the file and add a rule that drops only the `status="500"` series of `lab_requests_total`. Use the source labels `__name__` and `status`, the default separator and a regex that matches both values joined by a semicolon.

When you are done, run `astrona destroy ats-048-playground-020-02` to remove the environment.

## Exercise 7: Compare the stages in the service discovery view

Open the targets API once more and read `droppedTargets` and `activeTargets` after each exercise. Draw a small table in your notes with one row per target and three columns: the label set before relabeling, the label set after relabeling, and whether the target was scraped. Fill it in for the cases that you built: the plain target, the target with `instance` rewritten, the target with the wrong port and the target that a `drop` rule removed.

Look for one thing in the table: which changes appear only in the final labels, and which changes alter the connection. A rule on `instance` changes only a label. A rule on `__address__`, `__metrics_path__` or `__scheme__` changes the request. Write one sentence for each of the three internal labels that says what the scrape would do if a rule changed it.

## Exercise 8: Parameters and the metrics path

Set `metrics_path: /metric` for the job `probe`, reload, and read `lastError` and `up`. The application has no such path, so the answer is an HTTP error status. Then set the correct path again and add `params` with a parameter named `module` and a list with one value. Look at the `scrapeUrl` in the targets API: the parameter appears in the query string. The `probe` application ignores unknown parameters, so the target stays healthy.

Remove the parameter again and confirm that the URL returns to the plain `/metrics` path.

## Exercise 9: Combine the rules in one job

Put everything together in one job so that you practice the order of the rules. Build a job `probe` with these effects, and predict the final label set before you reload:

- The label `tier` has the value `backend`.
- The label `instance` has the value `probe-main`.
- The label `host` has the value `probe`, copied from `__address__`.
- The metric `lab_queue_depth` is not stored.
- The label `team` is removed from every sample.

Reload and check the result in the targets API and with a query on `lab_requests_total`. If a result differs from your prediction, find the rule that caused it. A common cause is the order: a rule that reads `__address__` must come before a rule that rewrites it.

## Things to check yourself

- Which list of rules runs before the scrape, and which after?
- Why is a regex of `lab_queue` not enough to drop `lab_queue_depth`?
- Which label set holds the label `__metrics_path__`: before or after relabeling?
- What does `honor_labels: true` change when a scraped sample has its own `job` label?
