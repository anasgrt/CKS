#!/bin/bash
# Setup for Question 08 - ServiceAccount Token Mounting with Projected Volume

set -e

echo "Setting up Question 08 - ServiceAccount Token Mounting..."

# Create namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Create ServiceAccount with auto-mount enabled (user needs to disable it)
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: stats-monitor-sa
  namespace: monitoring
automountServiceAccountToken: true
EOF

# Create Deployment without projected volume (user needs to add it)
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stats-monitor
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: stats-monitor
  template:
    metadata:
      labels:
        app: stats-monitor
    spec:
      serviceAccountName: stats-monitor-sa
      containers:
      - name: stats
        image: busybox:1.36
        command: ["sleep", "3600"]
EOF

# Create home directory structure for deployment manifest
mkdir -p ~/stats-monitor

# Export deployment manifest to the expected location
kubectl get deployment stats-monitor -n monitoring -o yaml > ~/stats-monitor/deployment.yaml

# Wait for deployment
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available deployment/stats-monitor -n monitoring --timeout=60s 2>/dev/null || true

echo ""
echo "✓ Environment ready!"
echo ""
echo "Namespace: monitoring"
echo "ServiceAccount: stats-monitor-sa"
echo "Deployment: stats-monitor"
echo ""
echo "Current ServiceAccount config:"
kubectl get sa stats-monitor-sa -n monitoring -o yaml | grep -A2 "automountServiceAccountToken" || echo "  automountServiceAccountToken: true (default)"
echo ""
echo "Deployment manifest location:"
echo "  ~/stats-monitor/deployment.yaml"
echo ""
echo "Check current deployment:"
echo "  kubectl get deployment stats-monitor -n monitoring -o yaml"
