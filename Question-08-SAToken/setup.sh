#!/bin/bash
# Setup for Question 08 - ServiceAccount Token Mounting with Projected Volume

set -e

echo "Setting up Question 08 - ServiceAccount Token Mounting..."

# Create namespace
kubectl create namespace secure --dry-run=client -o yaml | kubectl apply -f -

# Create ServiceAccount with auto-mount enabled (user needs to disable it)
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend-sa
  namespace: secure
automountServiceAccountToken: true
EOF

# Create Deployment without projected volume (user needs to add it)
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deploy
  namespace: secure
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      serviceAccountName: backend-sa
      containers:
      - name: backend
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
EOF

# Create output directory
mkdir -p /opt/course/08

# Wait for deployment
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available deployment/backend-deploy -n secure --timeout=60s 2>/dev/null || true

echo ""
echo "✓ Environment ready!"
echo ""
echo "Namespace: secure"
echo "ServiceAccount: backend-sa"
echo "Deployment: backend-deploy"
echo ""
echo "Current ServiceAccount config:"
kubectl get sa backend-sa -n secure -o yaml | grep -A2 "automountServiceAccountToken" || echo "  automountServiceAccountToken: true (default)"
echo ""
echo "Check deployment:"
echo "  kubectl get deployment backend-deploy -n secure -o yaml"
