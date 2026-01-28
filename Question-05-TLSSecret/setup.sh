#!/bin/bash
# Setup for Question 05 - Create TLS Secret

set -e

echo "Setting up Question 05 - TLS Secret..."

# Create output directory
mkdir -p /opt/course/05

# Create namespace
kubectl create namespace secure-ns --dry-run=client -o yaml | kubectl apply -f -

# Generate self-signed certificate and key
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /opt/course/05/tls.key \
    -out /opt/course/05/tls.crt \
    -subj "/CN=my-service.secure-ns.svc/O=CKS-Exam" 2>/dev/null

echo ""
echo "✓ Environment ready!"
echo ""
echo "Certificate: /opt/course/05/tls.crt"
echo "Key: /opt/course/05/tls.key"
echo "Target namespace: secure-ns"
echo "Target secret name: my-tls-secret"
echo ""
echo "Hint: Use 'kubectl create secret tls --help' for syntax"
