#!/bin/bash
# Solution for Question 13 - Kubelet Security Configuration

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Kubelet Security Configuration"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: SSH to the node and backup config"
echo "──────────────────────────────────────────"
echo ""
cat << 'EOF'
# SSH to the worker node
ssh node-01

# Create output directory
mkdir -p /opt/course/13

# Backup current kubelet config
sudo cp /var/lib/kubelet/config.yaml /opt/course/13/kubelet-before.yaml
EOF

echo ""
echo "STEP 2: Edit the kubelet configuration"
echo "──────────────────────────────────────"
echo ""
cat << 'EOF'
# Edit the kubelet config
sudo vi /var/lib/kubelet/config.yaml

# Find and modify these sections:

authentication:
  anonymous:
    enabled: false      # <-- Change to false
  webhook:
    cacheTTL: 0s
    enabled: true       # <-- Ensure this is true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook         # <-- Change to Webhook (not AlwaysAllow)
  webhook:
    cacheAuthorizedTTL: 0s
    cacheUnauthorizedTTL: 0s
EOF

echo ""
echo "STEP 3: Restart kubelet"
echo "───────────────────────"
echo ""
cat << 'EOF'
# Restart the kubelet service
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Check kubelet status
sudo systemctl status kubelet
EOF

echo ""
echo "STEP 4: Verify and save config"
echo "──────────────────────────────"
echo ""
cat << 'EOF'
# Save the updated config
sudo cp /var/lib/kubelet/config.yaml /opt/course/13/kubelet-after.yaml

# Exit SSH
exit

# Verify node is Ready
kubectl get nodes
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "SECURE KUBELET CONFIG EXAMPLE:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
cat << 'EOF'
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 0s
    cacheUnauthorizedTTL: 0s
# ... rest of config
EOF

echo ""
echo "KEY POINTS:"
echo "  - anonymous.enabled: false - Blocks unauthenticated access"
echo "  - webhook.enabled: true - Enables token authentication"
echo "  - authorization.mode: Webhook - Uses API server for authorization"
echo ""
echo "INSECURE SETTINGS TO AVOID:"
echo "  - anonymous.enabled: true"
echo "  - authorization.mode: AlwaysAllow"
echo "  - readOnlyPort: 10255 (should be 0 or absent)"
