#!/usr/bin/env bash
# The alerting rule exists with the required for duration and label.
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

prom /api/v1/rules | check "any(r.get('name')=='LabHighErrorRatio' and r.get('type')=='alerting' and r.get('duration')==10 and r.get('labels',{}).get('severity')=='page' and r.get('health')=='ok' for g in d['data']['groups'] for r in g['rules'])" || fail "LabHighErrorRatio is missing, unhealthy, or does not have for: 10s and severity=page"
echo "PASS: the alerting rule is defined"
