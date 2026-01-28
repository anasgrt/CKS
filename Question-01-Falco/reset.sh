#!/bin/bash
# Reset Question 01 - Falco Runtime Security Detection

set -e

# Delete deployments and namespace
kubectl delete deployment nvidia-gpu cpu ollama -n apps --ignore-not-found 2>/dev/null || true
kubectl delete namespace apps --ignore-not-found 2>/dev/null || true

# Clean up output directory
rm -rf /opt/course/01

echo "Question 01 reset complete!"
