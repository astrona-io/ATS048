# Overview: Explore The Prometheus Configuration File (Playground)

This is a playground, not a lab. It starts a fresh cluster with Prometheus and the example application, and then waits. There is no task, no `astrona submit` and no pass or fail. Change the configuration, break it on purpose, run `astrona destroy` and start again.

## What is in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` points at it as the cluster administrator.
- Prometheus v3.5.5 in the namespace `starfleet`. It reads the key `prometheus.yaml` of the ConfigMap `prometheus-config` and starts with the flag `--web.enable-lifecycle`.
- The example application `probe`, with a Service of the same name on port 8080. It serves metrics at `/metrics`.
- A traffic generator that calls the `probe` application four times per second. Every tenth request fails with HTTP status 500.
- A pod `shuttle` with `wget`, for requests from inside the cluster network.

The starting file has the global values `scrape_interval: 2s` and `evaluation_interval: 2s`. It has two jobs: `probe`, with the target `probe:8080` and the label `team: starfleet`, and `prometheus`, with the target `localhost:9090`.

## Helpers

Paste these once in each new terminal. `api_get` sends a GET request to the Prometheus API from the `shuttle` pod. `reload_prometheus` restarts the deployment so that it reads the current ConfigMap and waits until it is ready.

```sh
api_get() {
  kubectl -n starfleet exec shuttle -- wget -qO- "http://prometheus:9090$1"
}
reload_prometheus() {
  kubectl -n starfleet rollout restart deployment/prometheus
  kubectl -n starfleet rollout status deployment/prometheus
}
```

Use them like this: `api_get /api/v1/targets`, `api_get '/api/v1/query?query=up'`, `reload_prometheus`.

## Exercise 1: Read the configuration in force

Request `/api/v1/status/config` and find the `probe` job in the text of the `yaml` field. Write down three values that you did not write in the file, such as the metrics path and the scheme. Then request `/api/v1/targets?state=active` and match the `scrapeUrl` of the `probe` target to those values.

Predict first: what is the scrape URL if you set `metrics_path: /stats` for the job? Change the file and check your answer in the targets API. The target becomes unhealthy because the application has no such path. Read the `lastError` field and the value of `up` for the job, then restore the path.

## Exercise 2: Break the target in two ways

Make the `probe` job unhealthy first with a wrong port (`probe:8081`) and then with a wrong path. For each failure, write down the text of `lastError`, the value of `up{job="probe"}`, and the value of `scrape_duration_seconds{job="probe"}`. The two errors must look different. Use the difference to decide in your own words which setting is wrong when you see each text.

Check that the traffic generator and the `probe` pod are not affected: `kubectl -n starfleet get pods` still shows them running. This is the point that `up` of 0 describes the scrape and not the application.

## Exercise 3: Intervals and timeouts

Give the job `probe` a `scrape_interval` of 5s and a `scrape_timeout` of 3s, and keep the global values. Reload and read `scrapeInterval` and `scrapeTimeout` for both jobs in the targets API.

Then try an invalid combination: set `scrape_interval: 1s` for the job without setting a timeout. Predict whether Prometheus accepts it, given the global timeout. Check the file with `promtool` before you load it:

```sh
kubectl -n starfleet exec deploy/prometheus -- promtool check config /config/prometheus.yaml
```

The ConfigMap volume updates with a delay, so wait about a minute after `kubectl apply` before you run the check, or run the restart and read the pod log with `kubectl -n starfleet logs deployment/prometheus`.

## Exercise 4: Labels on the target group

Add a second label `env: lab` to the target group of `probe`. After the reload, query `lab_requests_total` and check that every series has both `team` and `env`. Compare with a series that was stored before the change: wait for the new scrapes, then query a range or look at the timestamps. Samples from before the reload do not carry the new label.

Next, make a label conflict. Add `honor_labels: true` to the job and think about what would change if the application exposed a label named `job`. The `probe` application does not, so nothing visible changes. Write down in one sentence what would differ with `honor_labels: false`.

## Exercise 5: Reload without a restart

Edit the ConfigMap so that the global `scrape_interval` is 3s. Wait about a minute for the mounted file to update. Send the reload request:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- --post-data='' http://prometheus:9090/-/reload
```

Check the query `prometheus_config_last_reload_successful` and the `scrapeInterval` of the `prometheus` job. If the interval is still 2s, the mounted file was not updated yet. Wait and send the request again.

Finally, put an invalid value in the file, for example a `scrape_timeout` that is longer than the interval, and send the reload request again. Read the answer and the query result. The old configuration stays in force, and the metric `prometheus_config_last_reload_successful` shows 0. Restore the file and reload to bring it back to 1.

## Exercise 6: Read the Prometheus metrics about itself

Prometheus scrapes its own endpoint in the job `prometheus`. Use it to learn what the server reports about its configuration and its scrapes. Run these queries with `api_get` and write down the result of each:

- `prometheus_config_last_reload_successful`, which is 1 or 0.
- `prometheus_config_last_reload_success_timestamp_seconds`, the Unix time of the last successful load.
- `scrape_samples_scraped{job="probe"}`, the number of samples in one scrape of the application.
- `scrape_duration_seconds{job="prometheus"}`, the time of one scrape of the server itself.

Run the timestamp query before and after `reload_prometheus`. The value changes because the new pod loaded the file. Convert the number to a date with `date -r <number>` on macOS or `date -d @<number>` on Linux, and compare it with the current time.

Write the answer to one more question in your notes: if a colleague tells you that the application is down because `up` is 0, which three other facts would you check before you agree? Use `lastError`, the pod state and the duration of the scrape in your answer.

## Things to check yourself

- Which labels does every series from the job `probe` carry, and which of them came from the file?
- What is the difference between `scrape_timeout` and `evaluation_interval`?
- Why does a failed reload keep the server running?
- What does `promtool check config` not find?

When you are done, run `astrona destroy ats-048-playground-020-01` to remove the environment.
