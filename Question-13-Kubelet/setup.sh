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

echo ""
echo "✓ Environment ready!"
echo ""
echo "Target node: $WORKER_NODE"
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
