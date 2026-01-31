#!/bin/bash
# Setup for Question 14 - Ensure Immutability of Containers at Runtime

set -e

echo "Setting up Question 14 - Container Immutability and Security..."

# Create namespaces
kubectl create namespace immutable-ns --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace lamp --dry-run=client -o yaml | kubectl apply -f -

# Create nginx deployment without immutability
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

# Create lamp-deployment with insecure configuration
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lamp-deployment
  namespace: lamp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: lamp
  template:
    metadata:
      labels:
        app: lamp
    spec:
      containers:
      - name: lamp
        image: php:8.2-apache
        ports:
        - containerPort: 80
        securityContext:
          allowPrivilegeEscalation: true
EOF

# Create output directory
mkdir -p /opt/course/14

# Wait for deployments
echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available deployment/nginx -n immutable-ns --timeout=60s 2>/dev/null || true
kubectl wait --for=condition=available deployment/lamp-deployment -n lamp --timeout=60s 2>/dev/null || true

echo ""
echo "✓ Environment ready!"
echo ""
echo "Task 1 - Nginx Immutability:"
echo "  Namespace: immutable-ns"
echo "  Deployment: nginx"
echo "  Current status:"
kubectl get deployment nginx -n immutable-ns
echo ""
echo "Task 2 - LAMP Security:"
echo "  Namespace: lamp"
echo "  Deployment: lamp-deployment"
echo "  Current status:"
kubectl get deployment lamp-deployment -n lamp
echo ""
echo "To make nginx immutable, add:"
echo "  securityContext:"
echo "    readOnlyRootFilesystem: true"
echo ""
echo "For lamp-deployment, add:"
echo "  securityContext:"
echo "    runAsUser: 20000"
echo "    readOnlyRootFilesystem: true"
echo "    allowPrivilegeEscalation: false"
