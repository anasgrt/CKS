#!/bin/bash
# Solution for Question 06 - Docker Daemon Security Hardening

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Docker Daemon Security Hardening"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: SSH to the node"
echo "───────────────────────"
echo ""
cat << 'EOF'
# SSH to the specified node
ssh node-01
EOF

echo ""
echo "STEP 2: Save current socket permissions"
echo "───────────────────────────────────────"
echo ""
cat << 'EOF'
# Check and save current permissions
ls -la /var/run/docker.sock > /opt/course/06/socket-before.txt
cat /opt/course/06/socket-before.txt
EOF

echo ""
echo "STEP 3: Remove user from docker group"
echo "─────────────────────────────────────"
echo ""
cat << 'EOF'
# Check current groups for developer
id developer

# Remove developer from docker group
sudo gpasswd -d developer docker

# Verify user is removed
id developer
# Should not show 'docker' group
EOF

echo ""
echo "STEP 4: Configure Docker daemon"
echo "───────────────────────────────"
echo ""
cat << 'EOF'
# Edit Docker daemon configuration
sudo vi /etc/docker/daemon.json

# Set content to (remove any tcp:// hosts, set group to root):
{
    "group": "root"
}

# If file had "hosts" with tcp://, remove it:
# BAD:  {"hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"]}
# GOOD: {"group": "root"}

# Save the daemon.json
sudo cp /etc/docker/daemon.json /opt/course/06/daemon.json
EOF

echo ""
echo "STEP 5: Restart Docker daemon"
echo "─────────────────────────────"
echo ""
cat << 'EOF'
# Restart Docker
sudo systemctl restart docker

# Verify Docker is running
sudo systemctl status docker
EOF

echo ""
echo "STEP 6: Verify socket permissions"
echo "─────────────────────────────────"
echo ""
cat << 'EOF'
# Check new socket permissions
ls -la /var/run/docker.sock > /opt/course/06/socket-after.txt
cat /opt/course/06/socket-after.txt

# Should show: srw-rw---- root root ... /var/run/docker.sock
EOF

echo ""
echo "STEP 7: Verify cluster health"
echo "─────────────────────────────"
echo ""
cat << 'EOF'
# Exit SSH session
exit

# Check cluster health
kubectl get nodes
kubectl get pods -A
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "QUICK COMMANDS (run on node):"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "sudo gpasswd -d developer docker"
echo 'echo '"'"'{"group": "root"}'"'"' | sudo tee /etc/docker/daemon.json'
echo "sudo systemctl restart docker"
echo "ls -la /var/run/docker.sock"
echo ""

echo "KEY POINTS:"
echo "  - Docker socket access = root access on the host"
echo "  - Never expose Docker on TCP without TLS"
echo "  - Minimize users in docker group"
echo "  - Use 'group': 'root' in daemon.json for socket ownership"
