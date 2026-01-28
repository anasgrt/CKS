#!/bin/bash
# Reset Question 14 - Ensure Immutability of Containers at Runtime

kubectl delete deployment nginx -n immutable-ns --ignore-not-found 2>/dev/null || true
kubectl delete namespace immutable-ns --ignore-not-found 2>/dev/null || true

rm -rf /opt/course/14

echo "Question 14 reset complete!"
