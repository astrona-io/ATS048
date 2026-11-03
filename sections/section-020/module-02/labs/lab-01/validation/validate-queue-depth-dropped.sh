#!/usr/bin/env bash
# One metric is dropped and the others stay.
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

promq 'lab_queue_depth{job="probe"}' | check "len(d['data']['result'])==0" || fail "lab_queue_depth is still stored"
promq 'lab_last_success_timestamp_seconds{job="probe"}' | check "len(d['data']['result'])==1" || fail "lab_last_success_timestamp_seconds was dropped too; the rule is too broad"
promq 'lab_requests_total{job="probe"}' | check "len(d['data']['result'])>=2" || fail "lab_requests_total was dropped too; the rule is too broad"
echo "PASS: only lab_queue_depth is dropped"
