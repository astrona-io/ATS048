#!/usr/bin/env bash
# The regular expression matcher selects two paths.
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

promq 'lab:shop_requests:sum' | check "len(d['data']['result'])==1 and float(d['data']['result'][0]['value'][1])==10100.0 and set(d['data']['result'][0]['metric'])=={'__name__'}" || fail "lab:shop_requests:sum must be 10100 (the /orders and /cart totals) with no labels"
echo "PASS: the matcher selects the shop paths"
