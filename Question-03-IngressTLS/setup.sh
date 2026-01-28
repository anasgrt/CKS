#!/bin/bash
# Setup for Question 03 - Ingress with TLS and HTTP to HTTPS Redirect

set -e

echo "Setting up Question 03 - Ingress with TLS..."

# Create namespace
kubectl create namespace secure-app --dry-run=client -o yaml | kubectl apply -f -

# Generate self-signed TLS certificate
mkdir -p /tmp/tls-certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /tmp/tls-certs/tls.key \
    -out /tmp/tls-certs/tls.crt \
    -subj "/CN=secure.example.com/O=CKS-Exam" 2>/dev/null

# Create TLS secret
kubectl create secret tls tls-secret \
    --cert=/tmp/tls-certs/tls.crt \
    --key=/tmp/tls-certs/tls.key \
    -n secure-app \
    --dry-run=client -o yaml | kubectl apply -f -

# Create a simple backend service and deployment
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: secure-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
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
  name: secure-service
  namespace: secure-app
spec:
  selector:
    app: secure-app
  ports:
  - port: 80
    targetPort: 80
EOF

# Create output directory
mkdir -p /opt/course/03

# Clean up temp files
rm -rf /tmp/tls-certs

echo ""
echo "✓ Environment ready!"
echo ""
echo "Namespace: secure-app"
echo "TLS Secret: tls-secret"
echo "Backend Service: secure-service (port 80)"
echo ""
echo "Check resources with:"
echo "  kubectl get all -n secure-app"
echo "  kubectl get secret tls-secret -n secure-app"
