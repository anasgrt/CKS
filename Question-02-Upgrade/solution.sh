#!/bin/bash
# Solution for Question 02 - Worker Node Kubernetes Upgrade

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Worker Node Kubernetes Upgrade"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Check current node versions"
echo "────────────────────────────────────"
echo ""
cat << 'EOF'
# Check all node versions
kubectl get nodes

# Save the current version
kubectl get nodes node-01 -o jsonpath='{.status.nodeInfo.kubeletVersion}' > /opt/course/02/node-version-before.txt
EOF

echo ""
echo "STEP 2: Drain the worker node"
echo "─────────────────────────────"
echo ""
cat << 'EOF'
# Drain the node (evict pods and mark unschedulable)
kubectl drain node-01 --ignore-daemonsets --delete-emptydir-data

# Verify node is cordoned
kubectl get nodes
# Should show SchedulingDisabled
EOF

echo ""
echo "STEP 3: SSH to the worker node and upgrade kubeadm"
echo "──────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# SSH to the worker node
ssh node-01

# Update package index
sudo apt-get update

# Check available versions
apt-cache madison kubeadm | head -5

# Upgrade kubeadm
sudo apt-get install -y kubeadm=1.34.1-1.1

# Verify kubeadm version
kubeadm version
EOF

echo ""
echo "STEP 4: Upgrade the node configuration"
echo "──────────────────────────────────────"
echo ""
cat << 'EOF'
# On the worker node, run:
sudo kubeadm upgrade node

# This upgrades the local kubelet configuration
EOF

echo ""
echo "STEP 5: Upgrade kubelet and kubectl"
echo "───────────────────────────────────"
echo ""
cat << 'EOF'
# Upgrade kubelet and kubectl
sudo apt-get install -y kubelet=1.34.1-1.1 kubectl=1.34.1-1.1

# Hold packages to prevent accidental upgrades
sudo apt-mark hold kubelet kubeadm kubectl
EOF

echo ""
echo "STEP 6: Restart kubelet"
echo "───────────────────────"
echo ""
cat << 'EOF'
# Reload systemd and restart kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Check kubelet status
sudo systemctl status kubelet

# Exit from the worker node
exit
EOF

echo ""
echo "STEP 7: Uncordon the node"
echo "─────────────────────────"
echo ""
cat << 'EOF'
# Back on the control plane, uncordon the node
kubectl uncordon node-01

# Verify node is Ready and schedulable
kubectl get nodes
EOF

echo ""
echo "STEP 8: Save the post-upgrade version"
echo "─────────────────────────────────────"
echo ""
cat << 'EOF'
# Save the new version
kubectl get nodes node-01 -o jsonpath='{.status.nodeInfo.kubeletVersion}' > /opt/course/02/node-version-after.txt

# Verify the upgrade
cat /opt/course/02/node-version-before.txt
cat /opt/course/02/node-version-after.txt
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "QUICK REFERENCE:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "kubectl drain node-01 --ignore-daemonsets --delete-emptydir-data"
echo "ssh node-01"
echo "sudo apt-get update && sudo apt-get install -y kubeadm=1.34.1-1.1"
echo "sudo kubeadm upgrade node"
echo "sudo apt-get install -y kubelet=1.34.1-1.1 kubectl=1.34.1-1.1"
echo "sudo systemctl daemon-reload && sudo systemctl restart kubelet"
echo "exit"
echo "kubectl uncordon node-01"
echo ""
echo "KEY POINTS:"
echo "  - Always drain before upgrade"
echo "  - Upgrade kubeadm first, then kubelet/kubectl"
echo "  - kubeadm upgrade node is for workers (not kubeadm upgrade apply)"
echo "  - Don't forget to uncordon after upgrade"
