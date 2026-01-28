#!/bin/bash
# Solution for Question 08 - ServiceAccount Token Mounting with Projected Volume

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: ServiceAccount Token Mounting with Projected Volume"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Edit the ServiceAccount to disable auto-mount"
echo "─────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Option 1: Edit directly
kubectl edit sa backend-sa -n secure
# Add: automountServiceAccountToken: false

# Option 2: Patch
kubectl patch sa backend-sa -n secure -p '{"automountServiceAccountToken": false}'

# Option 3: Export, edit, and apply
kubectl get sa backend-sa -n secure -o yaml > /opt/course/08/serviceaccount.yaml
# Edit to add automountServiceAccountToken: false
kubectl apply -f /opt/course/08/serviceaccount.yaml
EOF

echo ""
echo "STEP 2: Edit the Deployment to add projected volume"
echo "────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Export current deployment
kubectl get deployment backend-deploy -n secure -o yaml > /opt/course/08/deployment.yaml

# Edit to add projected volume and mount
# See complete manifest below

# Apply the changes
kubectl apply -f /opt/course/08/deployment.yaml
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "COMPLETE MANIFESTS:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "--- serviceaccount.yaml ---"
cat << 'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend-sa
  namespace: secure
automountServiceAccountToken: false
EOF

echo ""
echo "--- deployment.yaml ---"
cat << 'EOF'
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
        volumeMounts:
        - name: token
          mountPath: /var/run/secrets/kubernetes.io/serviceaccount
          readOnly: true
      volumes:
      - name: token
        projected:
          sources:
          - serviceAccountToken:
              expirationSeconds: 3600
              path: token
EOF

echo ""
echo "STEP 3: Apply and verify"
echo "────────────────────────"
echo ""
cat << 'EOF'
# Apply changes
kubectl apply -f /opt/course/08/serviceaccount.yaml
kubectl apply -f /opt/course/08/deployment.yaml

# Verify the pod has the token mounted
kubectl exec -n secure deployment/backend-deploy -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/

# Check token expiration
kubectl exec -n secure deployment/backend-deploy -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
EOF

echo ""
echo "KEY POINTS:"
echo "  - automountServiceAccountToken: false on SA prevents auto-mounting"
echo "  - Projected volumes allow fine-grained control over token mounting"
echo "  - expirationSeconds controls token lifetime (auto-rotated)"
echo "  - Always mount tokens as read-only"
echo "  - Projected volumes can include multiple sources (configMaps, secrets, etc.)"
