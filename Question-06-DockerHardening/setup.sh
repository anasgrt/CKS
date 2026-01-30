#!/bin/bash
# Setup for Question 06 - Docker Daemon Security Hardening

set -e

echo "Setting up Question 06 - Docker Daemon Hardening..."

# Create output directory
mkdir -p /opt/course/06

# Determine which node to configure (node01 or the first worker node)
NODE_NAME="node01"

# Check if we can reach the node
if ! kubectl get node $NODE_NAME &>/dev/null; then
    echo "⚠️  Node $NODE_NAME not found. Finding first worker node..."
    NODE_NAME=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -z "$NODE_NAME" ]; then
        echo "❌ No worker nodes found. Please ensure your cluster has worker nodes."
        exit 1
    fi
    echo "Using node: $NODE_NAME"
fi

echo ""
echo "Configuring Docker environment on $NODE_NAME..."

# Setup Docker environment on the node
kubectl get nodes -o name | grep -q "$NODE_NAME" && {
    # Create setup script to run on the node
    cat > /tmp/docker-setup.sh << 'EOFSCRIPT'
#!/bin/bash
set -e

# Install Docker if not present (for simulation purposes)
if ! command -v docker &> /dev/null; then
    echo "Installing Docker for exam simulation..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh &>/dev/null || echo "Docker installation skipped"
    rm -f /tmp/get-docker.sh
fi

# Create docker group if it doesn't exist
if ! getent group docker &>/dev/null; then
    groupadd docker
fi

# Create developer user if it doesn't exist
if ! id developer &>/dev/null; then
    useradd -m -s /bin/bash developer
    echo "developer:developer123" | chpasswd
fi

# Add developer to docker group
usermod -aG docker developer

# Create insecure Docker daemon configuration
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"],
  "group": "docker",
  "insecure-registries": ["registry.insecure.com"]
}
EOF

# Set insecure permissions on docker socket (intentionally insecure for the exercise)
if [ -e /var/run/docker.sock ]; then
    chown root:docker /var/run/docker.sock
    chmod 660 /var/run/docker.sock
fi

# Try to restart docker if systemd is available
if systemctl is-active docker &>/dev/null; then
    systemctl restart docker || true
fi

# Create output directory for the exercise
mkdir -p /opt/course/06

echo "✓ Docker environment configured on $(hostname)"
echo "  - User 'developer' created and added to docker group"
echo "  - Insecure daemon.json configuration in place"
echo "  - Output directory /opt/course/06 created"
echo "  - Docker socket has group ownership"
EOFSCRIPT

    chmod +x /tmp/docker-setup.sh

    # Copy and execute on the node
    echo "Executing setup on $NODE_NAME..."
    ssh $NODE_NAME 'bash -s' < /tmp/docker-setup.sh 2>/dev/null || {
        echo "⚠️  Could not SSH to $NODE_NAME directly."
        echo "Please run the following commands manually on $NODE_NAME:"
        echo ""
        cat /tmp/docker-setup.sh
        echo ""
    }

    rm -f /tmp/docker-setup.sh
}

echo ""
echo "✓ Environment setup complete!"
echo ""
echo "To start the exercise, SSH to the node:"
echo "  ssh $NODE_NAME"
echo ""
echo "Verify the insecure configuration:"
echo "  id developer"
echo "  cat /etc/docker/daemon.json"
echo "  ls -la /var/run/docker.sock"
echo ""
echo "Tasks to perform:"
echo "  1. Remove user 'developer' from docker group"
echo "  2. Change socket group ownership to 'root' in daemon.json"
echo "  3. Remove TCP listener (tcp://0.0.0.0:2375) from daemon.json"
echo "  4. Restart Docker daemon"
