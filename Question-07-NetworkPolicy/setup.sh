#!/bin/bash
# Setup for Question 07 - Network Policy

set -e

echo "Setting up Question 07 - Network Policy..."

# Create namespaces
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace data --dry-run=client -o yaml | kubectl apply -f -

# Label data namespace
kubectl label namespace data env=data --overwrite

# Label prod namespace
kubectl label namespace prod env=prod --overwrite

# Create test pods in prod namespace
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: prod-app
  namespace: prod
  labels:
    env: prod
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: prod-worker
  namespace: prod
  labels:
    env: worker
spec:
  containers:
  - name: busybox
    image: busybox:1.36
    command: ["sleep", "3600"]
EOF

# Create test pods in data namespace
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: database
  namespace: data
  labels:
    app: database
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: database-svc
  namespace: data
spec:
  selector:
    app: database
  ports:
  - port: 80
    targetPort: 80
EOF

# Create output directory
mkdir -p /opt/course/07

# Wait for pods
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l env=prod -n prod --timeout=60s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app=database -n data --timeout=60s 2>/dev/null || true

echo ""
echo "✓ Environment ready!"
echo ""
echo "Namespaces:"
echo "  - prod (label: env=prod)"
echo "  - data (label: env=data)"
echo ""
echo "Pods in prod:"
echo "  - prod-app (label: env=prod)"
echo "  - prod-worker (label: env=worker)"
echo ""
echo "Pods in data:"
echo "  - database (label: app=database)"
echo ""
echo "Test connectivity with:"
echo "  kubectl exec -n prod prod-app -- wget -qO- --timeout=2 database-svc.data"
