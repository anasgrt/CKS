#!/bin/bash
# Reset Question 12 - Dockerfile and Deployment Security

echo "Resetting Question 12 - Dockerfile and Deployment Security..."

# Delete deployment if it exists
kubectl delete deployment kafka -n team-blue --ignore-not-found 2>/dev/null || true

# Clean up files
rm -rf /opt/course/12

echo "Question 12 reset complete!"
