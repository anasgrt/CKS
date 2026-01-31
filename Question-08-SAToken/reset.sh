#!/bin/bash
# Reset Question 08 - ServiceAccount Token Mounting with Projected Volume

echo "Resetting Question 08 - ServiceAccount Token Mounting..."

kubectl delete deployment stats-monitor -n monitoring --ignore-not-found 2>/dev/null || true
kubectl delete sa stats-monitor-sa -n monitoring --ignore-not-found 2>/dev/null || true
kubectl delete namespace monitoring --ignore-not-found 2>/dev/null || true

rm -rf ~/stats-monitor

echo "Question 08 reset complete!"
