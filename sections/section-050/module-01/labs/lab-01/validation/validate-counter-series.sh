#!/usr/bin/env bash
# The counter has two series with correct labels.
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

promq 'lab_jobs_processed_total{job="exporter",queue="default"}' | check "sorted((r['metric'].get('result'), float(r['value'][1])) for r in d['data']['result'])==[('error',13.0),('ok',1027.0)]" || fail "lab_jobs_processed_total must have result=ok with 1027 and result=error with 13"
echo "PASS: the counter series are correct"
