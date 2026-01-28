#!/bin/bash
# Setup for Question 09 - Configure Kubernetes Auditing

set -e

echo "Setting up Question 09 - Kubernetes Auditing..."

# Create namespace for testing
kubectl create namespace audit-test --dry-run=client -o yaml | kubectl apply -f -

# Create output directory
mkdir -p /opt/course/09

echo ""
echo "✓ Environment ready!"
echo ""
echo "Important paths:"
echo "  API server manifest: /etc/kubernetes/manifests/kube-apiserver.yaml"
echo "  Audit policy: /etc/kubernetes/audit/policy.yaml"
echo "  Audit logs: /var/log/kubernetes/audit/"
echo ""
echo "Audit levels:"
echo "  - None: don't log"
echo "  - Metadata: log request metadata (user, timestamp, resource, verb)"
echo "  - Request: log metadata + request body"
echo "  - RequestResponse: log metadata + request + response bodies"
echo ""
echo "After modifying the API server, wait 30-60 seconds for restart."
echo "Check API server status: kubectl get pods -n kube-system | grep api"
