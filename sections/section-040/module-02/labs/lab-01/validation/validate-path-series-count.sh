#!/usr/bin/env bash
# The series count per path.
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

promq 'path:lab_http_requests_total:series' | check "sorted((r['metric'].get('path'), float(r['value'][1])) for r in d['data']['result'])==[('/cart',100.0),('/orders',100.0),('/search',100.0)] and all(set(r['metric'])=={'__name__','path'} for r in d['data']['result'])" || fail "path:lab_http_requests_total:series must be 100 for each of the three paths"
echo "PASS: the series count per path is recorded"
