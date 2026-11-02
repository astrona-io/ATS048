---
draft: true
exam_objectives:
- Exposition Format
---
# Read Typed Prometheus Exposition

Record the actual HELP, TYPE and sample lines from the producer.

## Starting state

One instrumented probe serves metrics and structured request logs. A traffic generator makes ten percent of requests fail. Prometheus scrapes every two seconds; no evidence report or learner rule exists.

Use a host shell with the private kubeconfig for this independent kind environment. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-048-lab-050-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-048-lab-050-01-01" || exit 1
node_name="astro-ats-048-lab-050-01-01-control-plane"
worker_name="astro-ats-048-lab-050-01-01-worker"
```

Keep this connection selected. Host-level commands name only this environment's node containers. They do not operate on the host operating system.

## Required result

Store a `types` map containing lab_requests_total: counter, lab_queue_depth: gauge and lab_request_duration_seconds: histogram. Check the live endpoint; a handwritten sample alone is not evidence.

Record observations in `starfleet/evidence`, whose `report.json` contains the stated report. The verifier reads the live API again; invented values do not pass.

The report object uses these fields: `types`. Keep numeric values numeric and preserve arrays and nested objects returned by the API.

## Verify The Result

The grader checks the required object fields and actual observations. Wait for controller convergence before submitting. Preserve the task's namespace, workload names and unrelated components.
