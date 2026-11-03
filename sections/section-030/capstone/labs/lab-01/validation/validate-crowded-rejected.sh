#!/usr/bin/env bash
# The over-limit scrape is rejected.
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

prom '/api/v1/targets?state=active' | check "any(t['labels'].get('job')=='crowded' and t['health']=='down' and 'sample limit' in t.get('lastError','').lower() for t in d['data']['activeTargets'])" || fail "the crowded target is not down with a sample limit error"
promq 'count(lab_ticket_info)' | check "len(d['data']['result'])==0" || fail "lab_ticket_info series are still stored"
echo "PASS: the crowded scrape is rejected"
