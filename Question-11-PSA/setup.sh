#!/bin/bash
# Setup for Question 11 - Pod Security Admission

set -e

echo "Setting up Question 11 - Pod Security Admission..."

# Create namespace
kubectl create namespace team-blue --dry-run=client -o yaml | kubectl apply -f -

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
  - name: nginx
    image: nginx:1.25-alpine
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: cache
      mountPath: /var/cache/nginx
    - name: run
      mountPath: /var/run
  volumes:
  - name: tmp
    emptyDir: {}
  - name: cache
    emptyDir: {}
  - name: run
    emptyDir: {}
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
