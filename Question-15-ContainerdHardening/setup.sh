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

# Setup on worker node: create vulnerable configuration
echo "Setting up vulnerable configuration on $WORKER_NODE..."
ssh "$WORKER_NODE" << 'REMOTE_SCRIPT'
# Create containerd group if not exists
if ! getent group containerd &>/dev/null; then
    sudo groupadd containerd
    echo "✓ Created group 'containerd'"
fi

# Create developer user if not exists
if ! id developer &>/dev/null; then
    sudo useradd -m -s /bin/bash developer
    echo "✓ Created user 'developer'"
fi

# Add developer to containerd group (insecure - for the exercise)
sudo usermod -aG containerd developer
echo "✓ Added 'developer' to containerd group"

# Change socket group to containerd (insecure - for the exercise)
sudo chown root:containerd /run/containerd/containerd.sock
sudo chmod 660 /run/containerd/containerd.sock
echo "✓ Changed socket group to 'containerd' (insecure)"

# Show current state
echo ""
echo "Current containerd socket permissions:"
ls -la /run/containerd/containerd.sock

echo ""
echo "User 'developer' groups:"
id developer
REMOTE_SCRIPT

echo ""
echo "✓ Vulnerable environment ready!"
echo ""
echo "Task: SSH to $WORKER_NODE and harden containerd security"
echo "  ssh $WORKER_NODE"
