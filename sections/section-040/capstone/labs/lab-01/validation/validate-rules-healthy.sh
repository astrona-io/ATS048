#!/usr/bin/env bash
# The rules are loaded and healthy.
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

prom /api/v1/rules | check "all(any(g['file'].startswith('/rules/') and any(r.get('name')==n and r.get('type')=='recording' and r.get('health')=='ok' for r in g['rules']) for g in d['data']['groups']) for n in ['job:lab_requests:rate1m','lab:requests_failed:rate1m','path:lab_http_requests:sum','lab:request_duration_seconds:p90'])" || fail "not all four recording rules are loaded and healthy"
echo "PASS: the rules are loaded"
