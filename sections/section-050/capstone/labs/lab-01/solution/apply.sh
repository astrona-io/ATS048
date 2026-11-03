#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
kubectl -n starfleet rollout restart deployment/exporter
kubectl -n starfleet rollout status deployment/exporter --timeout=180s
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus --timeout=180s
# Give Prometheus time to scrape and evaluate rules a few times.
sleep 30
echo "[solution] Applied."
