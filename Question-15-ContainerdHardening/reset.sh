#!/bin/bash
# Reset Question 15 - Containerd Security Hardening

# Automatically detect worker node
NODE=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$NODE" ]; then
    echo "✗ No worker nodes found in cluster"
    exit 1
fi

echo "Resetting Question 15 on $NODE..."

ssh "$NODE" << 'REMOTE_SCRIPT'
# Restore original containerd config if backup exists
if [ -f /etc/containerd/config.toml.backup ]; then
    sudo cp /etc/containerd/config.toml.backup /etc/containerd/config.toml
    echo "✓ Restored original containerd config"
fi

# Restart containerd
sudo systemctl restart containerd
echo "✓ Restarted containerd"

# Restore socket to root:root (in case it was changed)
sudo chown root:root /run/containerd/containerd.sock 2>/dev/null || true

# Remove developer user if exists
if id developer &>/dev/null; then
    sudo userdel -r developer 2>/dev/null || true
    echo "✓ Removed developer user"
fi

# Remove containerd group if exists (only if not used by containerd itself)
if getent group containerd &>/dev/null; then
    # Check if group is used as primary group by any user
    if ! awk -F: -v gid=$(getent group containerd | cut -d: -f3) '$4==gid' /etc/passwd | grep -q .; then
        sudo groupdel containerd 2>/dev/null || true
        echo "✓ Removed containerd group"
    fi
fi

# Clean up output directory on node
rm -rf /opt/course/15 2>/dev/null || true
echo "✓ Cleaned /opt/course/15"
REMOTE_SCRIPT

echo ""
echo "Question 15 reset complete!"
