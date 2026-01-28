#!/bin/bash
# Reset Question 03 - Ingress with TLS and HTTP to HTTPS Redirect

kubectl delete ingress secure-ingress -n secure-app --ignore-not-found 2>/dev/null || true
kubectl delete deployment secure-app -n secure-app --ignore-not-found 2>/dev/null || true
kubectl delete service secure-service -n secure-app --ignore-not-found 2>/dev/null || true
kubectl delete secret tls-secret -n secure-app --ignore-not-found 2>/dev/null || true
kubectl delete namespace secure-app --ignore-not-found 2>/dev/null || true

rm -rf /opt/course/03

echo "Question 03 reset complete!"
