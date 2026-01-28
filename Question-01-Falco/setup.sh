#!/bin/bash
# Setup for Question 01 - Falco Runtime Security Detection

set -e

echo "Setting up Question 01 - Falco Runtime Security..."

# Create namespace
kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f -

# Create nvidia-gpu deployment (harmless)
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nvidia-gpu
  namespace: apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nvidia-gpu
  template:
    metadata:
      labels:
        app: nvidia-gpu
    spec:
      containers:
      - name: nvidia-gpu
        image: busybox:1.36
        command: ["sh", "-c", "while true; do echo 'GPU processing...'; sleep 30; done"]
EOF

# Create cpu deployment (harmless)
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu
  namespace: apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cpu
  template:
    metadata:
      labels:
        app: cpu
    spec:
      containers:
      - name: cpu
        image: busybox:1.36
        command: ["sh", "-c", "while true; do echo 'CPU processing...'; sleep 30; done"]
EOF

# Create ollama deployment (the malicious one - accessing /dev/mem)
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ollama
  namespace: apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ollama
  template:
    metadata:
      labels:
        app: ollama
    spec:
      containers:
      - name: ollama
        image: busybox:1.36
        command: ["sh", "-c", "while true; do cat /dev/mem 2>/dev/null || echo 'Accessing memory...'; sleep 10; done"]
        securityContext:
          privileged: true
EOF

# Create output directory
mkdir -p /opt/course/01

# Wait for pods to be ready
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=nvidia-gpu -n apps --timeout=60s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app=cpu -n apps --timeout=60s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app=ollama -n apps --timeout=60s 2>/dev/null || true

echo ""
echo "✓ Environment ready!"
echo ""
echo "Namespace: apps"
echo "Deployments: nvidia-gpu, cpu, ollama"
echo ""
echo "Check deployments with: kubectl get deployments -n apps"
echo "Check Falco logs with: journalctl -u falco -f"
echo "                   or: sudo cat /var/log/falco/falco.log"
