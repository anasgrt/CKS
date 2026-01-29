#!/bin/bash
# Setup for Question 02 - Worker Node Kubernetes Upgrade

set -e

echo "Setting up Question 02 - Worker Node Upgrade..."

# Create output directory
mkdir -p /opt/course/02

# Detect worker node
WORKER_NODE=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$WORKER_NODE" ]; then
    echo "✗ No worker nodes found in cluster"
    exit 1
fi

WORKER_VERSION=$(kubectl get node "$WORKER_NODE" -o jsonpath='{.status.nodeInfo.kubeletVersion}' 2>/dev/null)
CONTROL_PLANE_VERSION=$(kubectl get nodes --selector='node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].status.nodeInfo.kubeletVersion}' 2>/dev/null)

echo ""
echo "✓ Environment ready!"
echo ""
echo "Cluster Information:"
echo "  - Worker node: $WORKER_NODE"
echo "  - Worker version: $WORKER_VERSION"
echo "  - Control plane version: $CONTROL_PLANE_VERSION"
echo "  - Target version: v1.34.1"
echo ""
echo "Important notes:"
echo "  - This question tests your knowledge of the upgrade process"
echo "  - You need to upgrade the worker node to match control plane version"
echo ""
echo "Check node versions with: kubectl get nodes"
echo ""
echo "Key commands to remember (per Official K8s Docs):"
echo "  1. ssh $WORKER_NODE"
echo "  2. sudo apt update && sudo apt-cache madison kubeadm"
echo "  3. sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get install -y kubeadm='1.34.1-1.1' && sudo apt-mark hold kubeadm"
echo "  4. sudo kubeadm upgrade node"
echo "  5. kubectl drain $WORKER_NODE --ignore-daemonsets  # (from controlplane)"
echo "  6. sudo apt-mark unhold kubelet kubectl && sudo apt-get update && sudo apt-get install -y kubelet='1.34.1-1.1' kubectl='1.34.1-1.1' && sudo apt-mark hold kubelet kubectl"
echo "  7. sudo systemctl daemon-reload && sudo systemctl restart kubelet"
echo "  8. exit (from SSH)"
echo "  9. kubectl uncordon $WORKER_NODE"
