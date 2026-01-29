#!/bin/bash
# Setup for Question 15 - Containerd Security Hardening

set -e

echo "Setting up Question 15 - Containerd Hardening..."

# Create output directory
mkdir -p /opt/course/15

# Get a worker node
WORKER_NODE=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}')
if [ -z "$WORKER_NODE" ]; then
    WORKER_NODE="node-01"
fi

echo "Target node: $WORKER_NODE"

# Setup on worker node: create developer user
echo "Setting up scenario on $WORKER_NODE..."
ssh "$WORKER_NODE" << 'REMOTE_SCRIPT'
# Create developer user if not exists
if ! id developer &>/dev/null; then
    sudo useradd -m -s /bin/bash developer
    echo "✓ Created user 'developer'"
else
    echo "✓ User 'developer' already exists"
fi

# Show current containerd socket permissions
echo ""
echo "Current containerd socket permissions:"
ls -la /run/containerd/containerd.sock 2>/dev/null || echo "Socket not found at expected location"

# Show containerd config location
echo ""
echo "Containerd config:"
ls -la /etc/containerd/config.toml 2>/dev/null || echo "Config not found"

# Show user info
echo ""
echo "User 'developer' groups:"
id developer
REMOTE_SCRIPT

echo ""
echo "✓ Environment ready!"
echo ""
echo "Task: SSH to $WORKER_NODE and verify containerd security"
echo "  ssh $WORKER_NODE"
