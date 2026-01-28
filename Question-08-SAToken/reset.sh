#!/bin/bash
# Reset Question 08 - ServiceAccount Token Mounting with Projected Volume

kubectl delete deployment backend-deploy -n secure --ignore-not-found 2>/dev/null || true
kubectl delete sa backend-sa -n secure --ignore-not-found 2>/dev/null || true
kubectl delete namespace secure --ignore-not-found 2>/dev/null || true

rm -rf /opt/course/08

echo "Question 08 reset complete!"
