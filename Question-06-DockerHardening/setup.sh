#!/bin/bash
# Setup for Question 06 - Docker Daemon Security Hardening

set -e

echo "Setting up Question 06 - Docker Daemon Hardening..."

# Create output directory
mkdir -p /opt/course/06

# Get a worker node
WORKER_NODE=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}')
if [ -z "$WORKER_NODE" ]; then
    WORKER_NODE="node-01"
fi

echo "Target node: $WORKER_NODE"

# Setup on worker node: create developer user and add to docker group
echo "Setting up vulnerable configuration on $WORKER_NODE..."
ssh "$WORKER_NODE" << 'REMOTE_SCRIPT'
# Create developer user if not exists
if ! id developer &>/dev/null; then
    sudo useradd -m -s /bin/bash developer
    echo "✓ Created user 'developer'"
fi

# Add developer to docker group
sudo usermod -aG docker developer
echo "✓ Added 'developer' to docker group"

# Ensure docker group owns the socket (insecure - for the exercise)
if [ -f /etc/docker/daemon.json ]; then
    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup
fi

# Create insecure daemon.json (with docker group)
echo '{"group": "docker"}' | sudo tee /etc/docker/daemon.json > /dev/null

# Restart docker to apply
sudo systemctl restart docker
echo "✓ Docker configured with insecure settings"

# Show current state
echo ""
echo "Current docker.sock permissions:"
ls -la /var/run/docker.sock
echo ""
echo "User 'developer' groups:"
id developer
REMOTE_SCRIPT

echo ""
echo "✓ Environment ready!"
echo ""
echo "Task: SSH to $WORKER_NODE and harden Docker daemon"
echo "  ssh $WORKER_NODE"
