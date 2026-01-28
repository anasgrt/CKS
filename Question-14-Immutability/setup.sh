#!/bin/bash
# Setup for Question 14 - Ensure Immutability of Containers at Runtime

set -e

echo "Setting up Question 14 - Container Immutability..."

# Create namespace
kubectl create namespace immutable-ns --dry-run=client -o yaml | kubectl apply -f -

# Create deployment without immutability
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: immutable-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
EOF

# Create output directory
mkdir -p /opt/course/14

# Wait for deployment
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available deployment/nginx -n immutable-ns --timeout=60s 2>/dev/null || true

echo ""
echo "✓ Environment ready!"
echo ""
echo "Namespace: immutable-ns"
echo "Deployment: nginx"
echo ""
echo "Current status:"
kubectl get deployment nginx -n immutable-ns
echo ""
echo "To make the container immutable, add:"
echo "  securityContext:"
echo "    readOnlyRootFilesystem: true"
echo ""
echo "Then add emptyDir volumes for writable paths:"
echo "  - /var/cache/nginx"
echo "  - /var/run"
