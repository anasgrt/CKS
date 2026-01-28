#!/bin/bash
# Reset Question 11 - Pod Security Admission

kubectl delete pod compliant-pod hostnetwork-pod root-pod escalation-pod -n team-blue --ignore-not-found 2>/dev/null || true
kubectl delete namespace team-blue --ignore-not-found 2>/dev/null || true

rm -rf /opt/course/11

echo "Question 11 reset complete!"
