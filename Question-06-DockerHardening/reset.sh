#!/bin/bash
# Reset Question 06 - Docker Daemon Security Hardening

rm -rf /opt/course/06

# Get the worker node
WORKER_NODE=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}')
if [ -z "$WORKER_NODE" ]; then
    WORKER_NODE="node-01"
fi

echo "Resetting Docker configuration on $WORKER_NODE..."

ssh "$WORKER_NODE" << 'REMOTE_SCRIPT'
# Remove developer user if exists
if id developer &>/dev/null; then
    sudo userdel -r developer 2>/dev/null || true
    echo "✓ Removed user 'developer'"
fi

# Restore original daemon.json if backup exists
if [ -f /etc/docker/daemon.json.backup ]; then
    sudo mv /etc/docker/daemon.json.backup /etc/docker/daemon.json
    echo "✓ Restored original daemon.json"
else
    # Default to empty config
    echo '{}' | sudo tee /etc/docker/daemon.json > /dev/null
    echo "✓ Reset daemon.json to default"
fi

# Restart docker
sudo systemctl restart docker
echo "✓ Docker restarted"
REMOTE_SCRIPT

echo ""
echo "Question 06 reset complete!"
