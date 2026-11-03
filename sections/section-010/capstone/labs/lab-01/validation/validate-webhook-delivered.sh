#!/usr/bin/env bash
# The webhook receiver got the notification.
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

kubectl -n starfleet exec shuttle -- wget -qO- http://probe:8080/hooks 2>/dev/null | check "any(a.get('labels',{}).get('alertname')=='LabHighErrorRatio' for p in d for a in p.get('alerts',[]))" || fail "the webhook receiver has no notification for LabHighErrorRatio yet"
echo "PASS: the webhook received the notification"
