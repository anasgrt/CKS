#!/bin/bash
# Reset Question 11 - Pod Security Admission

echo "Resetting Question 11 - Pod Security Admission..."

# Delete pods first (faster than waiting for namespace deletion)
kubectl delete pod compliant-pod hostnetwork-pod root-pod escalation-pod -n team-blue --ignore-not-found 2>/dev/null || true

# Delete namespace (this also removes any PSA labels)
kubectl delete namespace team-blue --ignore-not-found --wait=false 2>/dev/null || true

# Clean up output files
rm -rf /opt/course/11

echo "Question 11 reset complete!"
