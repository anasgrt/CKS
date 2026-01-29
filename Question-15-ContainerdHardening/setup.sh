#!/bin/bash
# Setup for Question 15 - Containerd Security Hardening

set -e

echo "Setting up Question 15 - Containerd Hardening..."

# Create output directory
mkdir -p /opt/course/15

# Get a worker node
WORKER_NODE=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$WORKER_NODE" ]; then
    echo "✗ No worker nodes found in cluster"
    exit 1
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

# Backup original config and add TCP listener
sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.backup

# Add insecure TCP listener to containerd config
sudo tee /etc/containerd/config.toml > /dev/null << 'CONTAINERD_CONFIG'
version = 2

[grpc]
  address = "/run/containerd/containerd.sock"
  tcp_address = "0.0.0.0:10000"

[plugins."io.containerd.grpc.v1.cri"]
  [plugins."io.containerd.grpc.v1.cri".containerd]
    snapshotter = "overlayfs"
    default_runtime_name = "runc"
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
    runtime_type = "io.containerd.runc.v2"
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
[plugins."io.containerd.grpc.v1.cri".cni]
  bin_dir = "/opt/cni/bin"
  conf_dir = "/etc/cni/net.d"
CONTAINERD_CONFIG

# Restart containerd with insecure config
sudo systemctl restart containerd

echo "✓ Added insecure TCP listener (port 10000) to containerd"

# Show current state
echo ""
echo "Current containerd socket permissions:"
ls -la /run/containerd/containerd.sock

echo ""
echo "User 'developer' groups:"
id developer

echo ""
echo "TCP listeners:"
ss -tlnp | grep -E "10000|containerd" || echo "Checking..."
REMOTE_SCRIPT

echo ""
echo "✓ Vulnerable environment ready!"
echo ""
echo "Task: SSH to $WORKER_NODE and harden containerd security"
echo "  ssh $WORKER_NODE"
