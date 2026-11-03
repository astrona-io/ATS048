#!/usr/bin/env bash
# The counter rate rule keeps only the status label.
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

promq 'status:lab_requests:rate1m' | check "sorted(r['metric'].get('status') for r in d['data']['result'])==['200','500'] and all(set(r['metric'])=={'__name__','status'} and float(r['value'][1])>0 for r in d['data']['result'])" || fail "status:lab_requests:rate1m must have one positive series for status 200 and one for 500, with only the status label"
echo "PASS: the counter rate is recorded per status"
