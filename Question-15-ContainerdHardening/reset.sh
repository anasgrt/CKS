#!/bin/bash
# Reset Question 15 - Containerd Security Hardening

rm -rf /opt/course/15

# Get the worker node
WORKER_NODE=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}')
if [ -z "$WORKER_NODE" ]; then
    WORKER_NODE="node-01"
fi

echo "Cleaning up on $WORKER_NODE..."

ssh "$WORKER_NODE" << 'REMOTE_SCRIPT'
# Restore socket to root:root
if [ -S /run/containerd/containerd.sock ]; then
    sudo chown root:root /run/containerd/containerd.sock
    sudo chmod 660 /run/containerd/containerd.sock
    echo "✓ Restored socket to root:root"
fi

# Remove developer user if exists
if id developer &>/dev/null; then
    sudo userdel -r developer 2>/dev/null || true
    echo "✓ Removed user 'developer'"
fi

# Remove containerd group if exists
if getent group containerd &>/dev/null; then
    sudo groupdel containerd 2>/dev/null || true
    echo "✓ Removed group 'containerd'"
fi

# Clean up output directory on node
rm -rf /opt/course/15 2>/dev/null || true
REMOTE_SCRIPT

echo ""
echo "Question 15 reset complete!"
