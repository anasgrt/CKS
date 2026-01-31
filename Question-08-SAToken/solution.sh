#!/bin/bash
# Solution for Question 08 - ServiceAccount Token Mounting with Projected Volume

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: ServiceAccount Token Mounting with Projected Volume"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Modify the ServiceAccount to turn off automounting"
echo "══════════════════════════════════════════════════════════"
echo ""
cat << 'EOF'
# Option 1: Edit directly
kubectl edit sa stats-monitor-sa -n monitoring
# Add: automountServiceAccountToken: false

# Option 2: Patch (quickest method)
kubectl patch sa stats-monitor-sa -n monitoring -p '{"automountServiceAccountToken": false}'

# Option 3: Export, edit, and apply
kubectl get sa stats-monitor-sa -n monitoring -o yaml > serviceaccount.yaml
# Edit to add automountServiceAccountToken: false
kubectl apply -f serviceaccount.yaml
EOF

echo ""
echo "STEP 2: Discover the audience for the API Server"
echo "══════════════════════════════════════════════════"
echo ""
cat << 'EOF'
# Method 1: Check OIDC configuration (most reliable)
kubectl get --raw /.well-known/openid-configuration | jq -r '.issuer'

# Method 2: Check API server flags
kubectl -n kube-system get pod kube-apiserver-<node> -o yaml | grep service-account-issuer

# The audience is typically: https://kubernetes.default.svc.cluster.local
EOF

echo ""
echo "STEP 3: Modify the Deployment to inject ServiceAccount token"
echo "═════════════════════════════════════════════════════════════"
echo ""
cat << 'EOF'
# The deployment manifest is at ~/stats-monitor/deployment.yaml
# Edit this file to add projected volume and volume mount

# Key changes needed:
# 1. Add a projected volume named "token" with serviceAccountToken source
# 2. Configure expirationSeconds: 3600
# 3. Configure audience (discovered in Step 2)
# 4. Add volumeMount to the container
# 5. Ensure mount is read-only

# Apply the changes
kubectl apply -f ~/stats-monitor/deployment.yaml
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "COMPLETE SOLUTION MANIFESTS:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "--- Modified ServiceAccount ---"
cat << 'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: stats-monitor-sa
  namespace: monitoring
automountServiceAccountToken: false
EOF

echo ""
echo "--- Modified Deployment (key sections) ---"
cat << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stats-monitor
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: stats-monitor
  template:
    metadata:
      labels:
        app: stats-monitor
    spec:
      serviceAccountName: stats-monitor-sa
      containers:
      - name: stats
        image: busybox:1.36
        command: ["sleep", "3600"]
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
              audience: https://kubernetes.default.svc.cluster.local
EOF

echo ""
echo "STEP 4: Apply and verify the changes"
echo "════════════════════════════════════"
echo ""
cat << 'EOF'
# Apply the changes
kubectl patch sa stats-monitor-sa -n monitoring -p '{"automountServiceAccountToken": false}'
kubectl apply -f ~/stats-monitor/deployment.yaml

# Verify ServiceAccount
kubectl get sa stats-monitor-sa -n monitoring -o yaml | grep automountServiceAccountToken

# Verify projected volume configuration (including audience)
kubectl get deployment stats-monitor -n monitoring -o yaml | grep -A8 "serviceAccountToken"

# Verify the pod has the token mounted correctly
kubectl get pods -n monitoring
kubectl exec -n monitoring deployment/stats-monitor -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/

# Check token exists
kubectl exec -n monitoring deployment/stats-monitor -- cat /var/run/secrets/kubernetes.io/serviceaccount/token | head -c 50
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "KEY CONCEPTS:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "WHY DISABLE AUTO-MOUNTING?"
echo "  - Reduces attack surface by limiting token availability"
echo "  - Prevents accidental exposure in compromised pods"
echo "  - Allows fine-grained control over which pods get tokens"
echo ""audience: Specifies intended API server (enhances security)"
echo "  - Automatic renewal before expiration"
echo "  - More secure than static secrets"
echo "  - Can combine multiple sources (SA token + configMap + secret)"
echo ""
echo "DISCOVERING AUDIENCE:"
echo "  - kubectl get --raw /.well-known/openid-configuration | jq -r '.issuer'"
echo "  - Typically: https://kubernetes.default.svc.cluster.local"
echo "  - Validates token is intended for this specific cluster"
echo ""
echo "SECURITY BEST PRACTICES:"
echo "  - Always mount tokens as read-only"
echo "  - Use shortest practical expirationSeconds"
echo "  - Always specify audience for API server validation
echo "SECURITY BEST PRACTICES:"
echo "  - Always mount tokens as read-only"
echo "  - Use shortest practical expirationSeconds"
echo "  - Only inject tokens into pods that need them"
echo ""
echo "⚠️  IMPORTANT - HOW PATH AND MOUNTPATH WORK:"
echo "  - mountPath: Directory where volume is mounted (/var/run/secrets/kubernetes.io/serviceaccount)"
echo "  - path: Filename created INSIDE that directory (token)"
echo "  - Final location: mountPath + path = /var/run/secrets/kubernetes.io/serviceaccount/token"
echo "  - DO NOT use subPath - it's not in the official docs and prevents token auto-rotation"

