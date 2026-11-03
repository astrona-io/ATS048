#!/usr/bin/env bash
# Types are known to Prometheus.
set -uo pipefail
# Ask the Prometheus HTTP API from inside the cluster (the shuttle pod has wget).
prom() { kubectl -n starfleet exec shuttle -- wget -qO- "http://prometheus:9090$1" 2>/dev/null; }
promq() { prom "/api/v1/query?query=$(python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1]))' "$1")"; }
alertmanager_api() { kubectl -n starfleet exec shuttle -- wget -qO- "http://alertmanager:9093$1" 2>/dev/null; }
# check '<python expression over d>' reads JSON on stdin; exit 0 when the expression is true.
check() {
  python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    ok = bool(eval(sys.argv[1]))
except Exception:
    ok = False
sys.exit(0 if ok else 1)' "$1"
}
fail() { echo "FAIL: $1"; exit 1; }

prom '/api/v1/metadata?metric=lab_jobs_processed_total' | check "d['data']['lab_jobs_processed_total'][0]['type']=='counter'" || fail "lab_jobs_processed_total has no counter type"
prom '/api/v1/metadata?metric=lab_workers' | check "d['data']['lab_workers'][0]['type']=='gauge'" || fail "lab_workers has no gauge type"
prom '/api/v1/metadata?metric=lab_queue_length' | check "d['data']['lab_queue_length'][0]['type']=='gauge'" || fail "lab_queue_length has no gauge type"
echo "PASS: the metric types are declared"
