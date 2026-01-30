#!/bin/bash
# Reset Question 06 - Docker Daemon Security Hardening

echo "Resetting Question 06 - Docker Daemon Hardening..."

rm -rf /opt/course/06

# Determine which node was configured
NODE_NAME="node01"
if ! kubectl get node $NODE_NAME &>/dev/null; then
    NODE_NAME=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
fi

if [ -z "$NODE_NAME" ]; then
    echo "⚠️  No worker nodes found in cluster"
    exit 0
fi

echo "Cleaning up Docker configuration on $NODE_NAME..."

# Create cleanup script
cat > /tmp/docker-cleanup.sh << 'EOFSCRIPT'
#!/bin/bash

# Remove developer user if exists
if id developer &>/dev/null; then
    userdel -r developer 2>/dev/null || true
    echo "  ✓ Removed user 'developer'"
fi

# Remove docker group if it was created and is empty
if getent group docker &>/dev/null; then
    DOCKER_GROUP_MEMBERS=$(getent group docker | cut -d: -f4)
    if [ -z "$DOCKER_GROUP_MEMBERS" ]; then
        groupdel docker 2>/dev/null || true
        echo "  ✓ Removed docker group"
    fi
fi

# Clean up daemon.json
if [ -f /etc/docker/daemon.json ]; then
    rm -f /etc/docker/daemon.json
    echo "  ✓ Removed daemon.json"
fi

# Restart docker if it's running
if systemctl is-active docker &>/dev/null; then
    systemctl restart docker 2>/dev/null || true
    echo "  ✓ Docker restarted"
fi

echo "✓ Cleanup complete on $(hostname)"
EOFSCRIPT

chmod +x /tmp/docker-cleanup.sh

# Execute cleanup on the node
ssh $NODE_NAME 'bash -s' < /tmp/docker-cleanup.sh 2>/dev/null || {
    echo "⚠️  Could not SSH to $NODE_NAME directly."
    echo "Please run these commands manually on $NODE_NAME:"
    echo ""
    cat /tmp/docker-cleanup.sh
}

rm -f /tmp/docker-cleanup.sh

echo ""
echo "✓ Question 06 reset complete!"
