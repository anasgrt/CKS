#!/bin/bash
# Solution for Question 15 - Containerd Security Hardening

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Containerd Security Hardening"
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
ls -la /run/containerd/containerd.sock > /opt/course/15/socket-before.txt
cat /opt/course/15/socket-before.txt
EOF

echo ""
echo "STEP 3: Remove user from container group"
echo "─────────────────────────────────────────"
echo ""
cat << 'EOF'
# Check current groups for developer
id developer

# Check for container-related groups
getent group | grep -iE "container|docker"

# Remove developer from any container group (if applicable)
sudo gpasswd -d developer containerd 2>/dev/null || true
sudo gpasswd -d developer docker 2>/dev/null || true

# Verify user is removed
id developer
# Should not show any container groups
EOF

echo ""
echo "STEP 4: Configure containerd socket ownership"
echo "──────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Ensure socket is owned by root:root
sudo chown root:root /run/containerd/containerd.sock
sudo chmod 660 /run/containerd/containerd.sock

# Edit containerd configuration if needed
sudo vi /etc/containerd/config.toml

# In the [grpc] section, ensure:
# - address = "/run/containerd/containerd.sock"
# - NO tcp:// addresses

# Save the config
sudo cp /etc/containerd/config.toml /opt/course/15/config.toml
EOF

echo ""
echo "STEP 5: Restart containerd daemon"
echo "──────────────────────────────────"
echo ""
cat << 'EOF'
# Restart containerd
sudo systemctl restart containerd

# Verify containerd is running
sudo systemctl status containerd
EOF

echo ""
echo "STEP 6: Verify socket permissions"
echo "──────────────────────────────────"
echo ""
cat << 'EOF'
# Check new socket permissions
ls -la /run/containerd/containerd.sock > /opt/course/15/socket-after.txt
cat /opt/course/15/socket-after.txt

# Should show: srw-rw---- root root ... /run/containerd/containerd.sock
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
echo "sudo gpasswd -d developer containerd 2>/dev/null || true"
echo "sudo chown root:root /run/containerd/containerd.sock"
echo "sudo chmod 660 /run/containerd/containerd.sock"
echo "sudo systemctl restart containerd"
echo "ls -la /run/containerd/containerd.sock"
echo ""

echo "KEY POINTS:"
echo "  - Containerd socket access = root access on the host"
echo "  - Never expose containerd on TCP without mTLS"
echo "  - Minimize users with socket access"
echo "  - Socket should be owned by root:root with mode 660"
# Then restart: sudo systemctl restart containerd
EOF
echo ""

echo "KEY POINTS:"
echo "  - Containerd socket should be owned by root:root"
echo "  - Socket permissions should be 0660 or more restrictive"
echo "  - Containerd should only listen on unix socket, not TCP"
echo "  - No non-root users should have direct socket access"
