#!/bin/bash
# Solution for Question 07 - Network Policy

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Network Policy - Deny All and Allow from Specific Namespace"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Create deny-all-ingress policy in prod namespace"
echo "─────────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Create the deny-all-ingress NetworkPolicy
cat << 'YAML' > /opt/course/07/deny-all-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
YAML

# Apply it
kubectl apply -f /opt/course/07/deny-all-ingress.yaml
EOF

echo ""
echo "STEP 2: Create allow-from-prod policy in data namespace"
echo "────────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Create the allow-from-prod NetworkPolicy
cat << 'YAML' > /opt/course/07/allow-from-prod.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-prod
  namespace: data
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          env: prod
      podSelector:
        matchLabels:
          env: prod
YAML

# Apply it
kubectl apply -f /opt/course/07/allow-from-prod.yaml
EOF

echo ""
echo "STEP 3: Verify the policies"
echo "───────────────────────────"
echo ""
cat << 'EOF'
# List policies
kubectl get networkpolicy -n prod
kubectl get networkpolicy -n data

# Describe policies
kubectl describe networkpolicy deny-all-ingress -n prod
kubectl describe networkpolicy allow-from-prod -n data
EOF

echo ""
echo "STEP 4: Test connectivity"
echo "─────────────────────────"
echo ""
cat << 'EOF'
# From prod-app (has env=prod label) - should SUCCEED
kubectl exec -n prod prod-app -- wget -qO- --timeout=2 database-svc.data

# From prod-worker (has env=worker label) - should FAIL
kubectl exec -n prod prod-worker -- wget -qO- --timeout=2 database-svc.data
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "COMPLETE MANIFESTS:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "--- deny-all-ingress.yaml ---"
cat << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF

echo ""
echo "--- allow-from-prod.yaml ---"
cat << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-prod
  namespace: data
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          env: prod
      podSelector:
        matchLabels:
          env: prod
EOF

echo ""
echo "KEY POINTS:"
echo "  - Empty podSelector {} means 'all pods in namespace'"
echo "  - No ingress rules = deny all ingress"
echo "  - namespaceSelector + podSelector in same '-' = AND condition"
echo "  - namespaceSelector and podSelector in separate '-' = OR condition"
echo ""
echo "IMPORTANT:"
echo "  - from: [{namespaceSelector: X, podSelector: Y}] = pods matching Y IN namespaces matching X (AND)"
echo "  - from: [{namespaceSelector: X}, {podSelector: Y}] = namespaces matching X OR pods matching Y"
