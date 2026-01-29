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
# Remove developer user if exists
if id developer &>/dev/null; then
    sudo userdel -r developer 2>/dev/null || true
    echo "✓ Removed user 'developer'"
fi

# Clean up output directory on node
rm -rf /opt/course/15 2>/dev/null || true
REMOTE_SCRIPT

echo ""
echo "Question 15 reset complete!"
