#!/bin/bash
# Setup for Question 02 - Worker Node Kubernetes Upgrade

set -e

echo "Setting up Question 02 - Worker Node Upgrade..."

# Create output directory
mkdir -p /opt/course/02

echo ""
echo "✓ Environment ready!"
echo ""
echo "Important notes:"
echo "  - This question tests your knowledge of the upgrade process"
echo "  - In a real exam, you would have a multi-node cluster"
echo "  - The node 'node01' would be at version 1.34.0"
echo "  - You need to upgrade it to 1.34.1"
echo ""
echo "Check node versions with: kubectl get nodes"
echo ""
echo "Key commands to remember:"
echo "  1. kubectl drain node01 --ignore-daemonsets --delete-emptydir-data"
echo "  2. ssh node01"
echo "  3. apt-get update && apt-get install -y kubeadm=1.34.1-*"
echo "  4. kubeadm upgrade node"
echo "  5. apt-get install -y kubelet=1.34.1-* kubectl=1.34.1-*"
echo "  6. systemctl daemon-reload && systemctl restart kubelet"
echo "  7. exit (from SSH)"
echo "  8. kubectl uncordon node01"
