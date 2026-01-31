#!/bin/bash
# Setup for Question 13 - Kubelet Security Configuration

set -e

echo "Setting up Question 13 - Kubelet Security..."

# Create output directory
mkdir -p /opt/course/13

# Detect worker node
WORKER_NODE=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$WORKER_NODE" ]; then
    echo "✗ No worker nodes found in cluster"
    exit 1
fi

echo "Configuring insecure kubelet settings on $WORKER_NODE..."

# SSH to node and make kubelet insecure for the exercise
ssh "$WORKER_NODE" << 'REMOTE_SCRIPT'
# Backup current config
sudo cp /var/lib/kubelet/config.yaml /var/lib/kubelet/config.yaml.bak

# Make kubelet INSECURE (for the exercise)
# 1. Enable anonymous authentication
sudo sed -i 's/anonymous:/anonymous:\n    enabled: true/' /var/lib/kubelet/config.yaml 2>/dev/null || true
sudo sed -i '/anonymous:/,/enabled:/{s/enabled: false/enabled: true/}' /var/lib/kubelet/config.yaml

# 2. Disable webhook authentication
sudo sed -i '/webhook:/,/enabled:/{s/enabled: true/enabled: false/}' /var/lib/kubelet/config.yaml

# 3. Set authorization mode to AlwaysAllow
sudo sed -i 's/mode: Webhook/mode: AlwaysAllow/' /var/lib/kubelet/config.yaml

# Restart kubelet with insecure settings
sudo systemctl restart kubelet
REMOTE_SCRIPT

# Wait for kubelet to restart
echo "Waiting for kubelet to restart..."
sleep 10

# Wait for node to be ready
echo "Waiting for node to be ready..."
kubectl wait --for=condition=Ready node/"$WORKER_NODE" --timeout=120s 2>/dev/null || true

echo ""
echo "✓ Environment ready!"
echo ""
echo "Target node: $WORKER_NODE"
echo ""
echo "⚠️  INSECURE SETTINGS APPLIED - Your task is to secure them!"
echo ""
echo "Current kubelet settings (INSECURE):"
echo "  authentication.anonymous.enabled: true"
echo "  authentication.webhook.enabled: false"
echo "  authorization.mode: AlwaysAllow"
echo ""
echo "This question tests your knowledge of kubelet security configuration."
echo ""
echo "Key file: /var/lib/kubelet/config.yaml"
echo ""
echo "Settings to configure:"
echo "  authentication:"
echo "    anonymous:"
echo "      enabled: false"
echo "    webhook:"
echo "      enabled: true"
echo "  authorization:"
echo "    mode: Webhook"
echo ""
echo "After changes, restart kubelet:"
echo "  sudo systemctl restart kubelet"
echo "  sudo systemctl status kubelet"
echo ""
echo "Verify node is Ready:"
echo "  kubectl get nodes"
