#!/bin/bash
# Setup for Question 11 - Pod Security Admission

set -e

echo "Setting up Question 11 - Pod Security Admission..."

# Clean up existing namespace if it exists (handles stuck/corrupted state)
if kubectl get namespace team-blue &>/dev/null; then
  echo "Cleaning up existing namespace..."
  kubectl delete namespace team-blue --wait=true --timeout=60s 2>/dev/null || true
  # Wait for namespace to be fully deleted
  echo "Waiting for namespace to be fully terminated..."
  while kubectl get namespace team-blue &>/dev/null; do
    sleep 2
  done
fi

# Create namespace fresh
kubectl create namespace team-blue

# Wait for default ServiceAccount to be created (Kubernetes creates it automatically)
echo "Waiting for default ServiceAccount..."
for i in {1..30}; do
  if kubectl get serviceaccount default -n team-blue &>/dev/null; then
    echo "Default ServiceAccount is ready"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "ERROR: Default ServiceAccount was not created in time"
    exit 1
  fi
  sleep 1
done

# Create compliant pod (restricted level)
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: compliant-pod
  namespace: team-blue
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep", "3600"]
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
EOF

# Create non-compliant pod 1 (hostNetwork - violates restricted)
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: hostnetwork-pod
  namespace: team-blue
spec:
  hostNetwork: true
  containers:
  - name: nginx
    image: nginx:1.25-alpine
EOF

# Create non-compliant pod 2 (runs as root - violates restricted)
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: root-pod
  namespace: team-blue
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    # No runAsNonRoot, no seccompProfile - violates restricted
EOF

# Create non-compliant pod 3 (allowPrivilegeEscalation not false - violates restricted)
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: escalation-pod
  namespace: team-blue
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    securityContext:
      # allowPrivilegeEscalation defaults to true if not set
      runAsUser: 1000
EOF

# Create output directory
mkdir -p /opt/course/11

# Wait for pods
echo "Waiting for pods to be ready..."
sleep 5

echo ""
echo "✓ Environment ready!"
echo ""
echo "Namespace: team-blue"
echo "Pods created:"
kubectl get pods -n team-blue
echo ""
echo "Use the dry-run command to identify violations:"
echo "  kubectl label --dry-run=server --overwrite ns team-blue pod-security.kubernetes.io/enforce=restricted"
