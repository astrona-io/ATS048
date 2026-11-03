#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet patch deployment prometheus --type=json -p '[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--storage.tsdb.retention.time=6h"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--storage.tsdb.retention.size=500MB"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--query.timeout=30s"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--query.max-samples=10000000"}
]'
kubectl -n starfleet rollout status deployment/prometheus --timeout=180s
sleep 20
echo "[solution] Applied."
