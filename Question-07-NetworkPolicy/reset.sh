#!/bin/bash
# Reset Question 07 - Network Policy

kubectl delete networkpolicy deny-all-ingress -n prod --ignore-not-found 2>/dev/null || true
kubectl delete networkpolicy allow-from-prod -n data --ignore-not-found 2>/dev/null || true
kubectl delete pod prod-app prod-worker -n prod --ignore-not-found 2>/dev/null || true
kubectl delete pod database -n data --ignore-not-found 2>/dev/null || true
kubectl delete service database-svc -n data --ignore-not-found 2>/dev/null || true
kubectl delete namespace prod data --ignore-not-found 2>/dev/null || true

rm -rf /opt/course/07

echo "Question 07 reset complete!"
