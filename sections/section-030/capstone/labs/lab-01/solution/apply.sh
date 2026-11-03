#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
kubectl -n starfleet patch deployment prometheus --type=json -p '[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--storage.tsdb.retention.time=12h"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--storage.tsdb.retention.size=1GB"}
]'
kubectl -n starfleet rollout status deployment/prometheus --timeout=180s
sleep 30
echo "[solution] Applied."
