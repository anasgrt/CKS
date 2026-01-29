#!/bin/bash
# Solution for Question 02 - Worker Node Kubernetes Upgrade
# Based on Official Kubernetes Documentation:
# https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/upgrading-linux-nodes/

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Worker Node Kubernetes Upgrade (1.34.0 → 1.34.1)"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Check current node versions (from controlplane)"
echo "────────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
kubectl get nodes

# Save the current version
kubectl get nodes node01 -o jsonpath='{.status.nodeInfo.kubeletVersion}' > /opt/course/02/node-version-before.txt
EOF

echo ""
echo "STEP 2: SSH to the worker node and upgrade kubeadm"
echo "──────────────────────────────────────────────────"
echo ""
cat << 'EOF'
ssh node01

# Check available kubeadm versions
sudo apt update
sudo apt-cache madison kubeadm

# Unhold, update, install kubeadm, then hold
sudo apt-mark unhold kubeadm && \
sudo apt-get update && sudo apt-get install -y kubeadm='1.34.1-1.1' && \
sudo apt-mark hold kubeadm

# Verify kubeadm version
kubeadm version
EOF

echo ""
echo "STEP 3: Upgrade the node configuration (on worker node)"
echo "────────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# This upgrades the local kubelet configuration
sudo kubeadm upgrade node
EOF

echo ""
echo "STEP 4: Drain the node (from controlplane - open new terminal)"
echo "──────────────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Execute on controlplane (not on worker node)
kubectl drain node01 --ignore-daemonsets
EOF

echo ""
echo "STEP 5: Upgrade kubelet and kubectl (on worker node)"
echo "────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Back on worker node via SSH
sudo apt-mark unhold kubelet kubectl && \
sudo apt-get update && sudo apt-get install -y kubelet='1.34.1-1.1' kubectl='1.34.1-1.1' && \
sudo apt-mark hold kubelet kubectl
EOF

echo ""
echo "STEP 6: Restart kubelet (on worker node)"
echo "────────────────────────────────────────"
echo ""
cat << 'EOF'
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Verify kubelet is running
sudo systemctl status kubelet

# Exit SSH session
exit
EOF

echo ""
echo "STEP 7: Uncordon the node (from controlplane)"
echo "─────────────────────────────────────────────"
echo ""
cat << 'EOF'
kubectl uncordon node01

# Verify node is Ready
kubectl get nodes
EOF

echo ""
echo "STEP 8: Save the post-upgrade version"
echo "─────────────────────────────────────"
echo ""
cat << 'EOF'
kubectl get nodes node01 -o jsonpath='{.status.nodeInfo.kubeletVersion}' > /opt/course/02/node-version-after.txt

# Verify
cat /opt/course/02/node-version-before.txt
cat /opt/course/02/node-version-after.txt
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "QUICK REFERENCE (per Official K8s Docs):"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "# 1. SSH to worker node"
echo "ssh node01"
echo ""
echo "# 2. Check available versions"
echo "sudo apt update"
echo "sudo apt-cache madison kubeadm"
echo ""
echo "# 3. Upgrade kubeadm"
echo "sudo apt-mark unhold kubeadm && \\"
echo "sudo apt-get update && sudo apt-get install -y kubeadm='1.34.1-1.1' && \\"
echo "sudo apt-mark hold kubeadm"
echo ""
echo "# 4. Upgrade node config"
echo "sudo kubeadm upgrade node"
echo ""
echo "# 5. Drain (from controlplane)"
echo "kubectl drain node01 --ignore-daemonsets"
echo ""
echo "# 6. Upgrade kubelet & kubectl (on worker)"
echo "sudo apt-mark unhold kubelet kubectl && \\"
echo "sudo apt-get update && sudo apt-get install -y kubelet='1.34.1-1.1' kubectl='1.34.1-1.1' && \\"
echo "sudo apt-mark hold kubelet kubectl"
echo ""
echo "# 7. Restart kubelet"
echo "sudo systemctl daemon-reload && sudo systemctl restart kubelet"
echo ""
echo "# 8. Exit and uncordon"
echo "exit"
echo "kubectl uncordon node01"
echo ""
echo "KEY POINTS:"
echo "  - Upgrade kubeadm FIRST, then run kubeadm upgrade node"
echo "  - Drain AFTER kubeadm upgrade node (per official docs)"
echo "  - Use apt-mark unhold/hold to manage package versions"
echo "  - kubeadm upgrade node (workers) vs kubeadm upgrade apply (control plane)"
