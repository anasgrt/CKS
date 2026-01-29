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
echo "STEP 2: Check and save socket permissions"
echo "──────────────────────────────────────────"
echo ""
cat << 'EOF'
# Check containerd socket permissions
ls -la /run/containerd/containerd.sock

# Save to output file
ls -la /run/containerd/containerd.sock > /opt/course/15/socket-permissions.txt

# Expected: srw-rw---- 1 root root ... /run/containerd/containerd.sock
# Socket should be owned by root:root with mode 660 or more restrictive
EOF

echo ""
echo "STEP 3: Check containerd gRPC configuration"
echo "────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Check if containerd listens on TCP (should be unix socket only)
grep -A10 "\[grpc\]" /etc/containerd/config.toml

# Save to output file
grep -A10 "\[grpc\]" /etc/containerd/config.toml > /opt/course/15/containerd-grpc.txt

# Expected output should show:
# [grpc]
#   address = "/run/containerd/containerd.sock"
#
# If you see tcp:// addresses, that's a security concern!
EOF

echo ""
echo "STEP 4: Check container-related groups"
echo "───────────────────────────────────────"
echo ""
cat << 'EOF'
# Find container-related groups
getent group | grep -iE "container|docker"

# Save to output file
getent group | grep -iE "container|docker" > /opt/course/15/container-groups.txt 2>/dev/null || echo "No container groups found" > /opt/course/15/container-groups.txt

# Check who has access to containerd socket
stat /run/containerd/containerd.sock
EOF

echo ""
echo "STEP 5: Verify cluster health"
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
echo "QUICK SOLUTION (run on node):"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
cat << 'EOF'
mkdir -p /opt/course/15
ls -la /run/containerd/containerd.sock > /opt/course/15/socket-permissions.txt
grep -A10 "\[grpc\]" /etc/containerd/config.toml > /opt/course/15/containerd-grpc.txt
getent group | grep -iE "container|docker" > /opt/course/15/container-groups.txt 2>/dev/null || echo "No container groups found" > /opt/course/15/container-groups.txt
EOF
echo ""

echo "═══════════════════════════════════════════════════════════════════"
echo "SECURITY HARDENING (if needed):"
echo "═══════════════════════════════════════════════════════════════════"
cat << 'EOF'
# If socket has wrong permissions, fix with:
sudo chmod 660 /run/containerd/containerd.sock
sudo chown root:root /run/containerd/containerd.sock

# If containerd has TCP listeners, edit /etc/containerd/config.toml:
# Remove any tcp:// addresses in [grpc] section
# Then restart: sudo systemctl restart containerd
EOF
echo ""

echo "KEY POINTS:"
echo "  - Containerd socket should be owned by root:root"
echo "  - Socket permissions should be 0660 or more restrictive"
echo "  - Containerd should only listen on unix socket, not TCP"
echo "  - No non-root users should have direct socket access"
