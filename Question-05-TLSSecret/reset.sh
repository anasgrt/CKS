#!/bin/bash
# Reset Question 05 - Create TLS Secret

kubectl delete secret my-tls-secret -n secure-ns --ignore-not-found 2>/dev/null || true
kubectl delete namespace secure-ns --ignore-not-found 2>/dev/null || true

rm -rf /opt/course/05

echo "Question 05 reset complete!"
