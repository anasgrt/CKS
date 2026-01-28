#!/bin/bash
# Setup for Question 13 - Kubelet Security Configuration

set -e

echo "Setting up Question 13 - Kubelet Security..."

# Create output directory
mkdir -p /opt/course/13

echo ""
echo "✓ Environment ready!"
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
