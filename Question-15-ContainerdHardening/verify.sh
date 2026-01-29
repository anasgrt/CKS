#!/bin/bash
# Verify Question 15 - Containerd Security Hardening

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true
NODE="node-01"

echo "Checking Containerd Security Hardening..."
echo ""

# Check socket-before.txt
echo "Part 1: Socket Before Changes"
echo "──────────────────────────────"
SOCKET_BEFORE=$(ssh $NODE "cat /opt/course/15/socket-before.txt 2>/dev/null")
if [ -n "$SOCKET_BEFORE" ]; then
    echo -e "${GREEN}✓ socket-before.txt exists${NC}"
    echo "$SOCKET_BEFORE"
else
    echo -e "${RED}✗ socket-before.txt not found at /opt/course/15/socket-before.txt${NC}"
    PASS=false
fi

echo ""

# Check socket-after.txt
echo "Part 2: Socket After Changes"
echo "─────────────────────────────"
SOCKET_AFTER=$(ssh $NODE "cat /opt/course/15/socket-after.txt 2>/dev/null")
if [ -n "$SOCKET_AFTER" ]; then
    echo -e "${GREEN}✓ socket-after.txt exists${NC}"
    echo "$SOCKET_AFTER"

    # Check that socket is owned by root:root
    if echo "$SOCKET_AFTER" | grep -q "root.*root"; then
        echo -e "${GREEN}✓ Socket is owned by root:root${NC}"
    else
        echo -e "${RED}✗ Socket is NOT owned by root:root${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ socket-after.txt not found at /opt/course/15/socket-after.txt${NC}"
    PASS=false
fi

echo ""

# Check user not in containerd group
echo "Part 3: User Group Membership"
echo "──────────────────────────────"
USER_GROUPS=$(ssh $NODE "id developer 2>/dev/null" || echo "user_not_found")
if echo "$USER_GROUPS" | grep -q "containerd"; then
    echo -e "${RED}✗ developer is still in containerd group${NC}"
    echo "$USER_GROUPS"
    PASS=false
else
    echo -e "${GREEN}✓ developer is NOT in containerd group${NC}"
fi

echo ""

# Check config.toml saved
echo "Part 4: Config Saved"
echo "─────────────────────"
CONFIG=$(ssh $NODE "cat /opt/course/15/config.toml 2>/dev/null")
if [ -n "$CONFIG" ]; then
    echo -e "${GREEN}✓ config.toml exists${NC}"

    # Check that TCP listener is removed
    if echo "$CONFIG" | grep -qi "tcp_address"; then
        echo -e "${RED}✗ tcp_address still exists in saved config${NC}"
        PASS=false
    else
        echo -e "${GREEN}✓ No tcp_address in saved config${NC}"
    fi
else
    echo -e "${RED}✗ config.toml not found at /opt/course/15/config.toml${NC}"
    PASS=false
fi

echo ""

# Check netstat-after.txt
echo "Part 5: TCP Port Verification"
echo "──────────────────────────────"
NETSTAT=$(ssh $NODE "cat /opt/course/15/netstat-after.txt 2>/dev/null")
if [ -n "$NETSTAT" ]; then
    echo -e "${GREEN}✓ netstat-after.txt exists${NC}"

    # Check that port 10000 is not listening
    if echo "$NETSTAT" | grep -q ":10000"; then
        echo -e "${RED}✗ Port 10000 appears in netstat-after.txt${NC}"
        PASS=false
    else
        echo -e "${GREEN}✓ Port 10000 is not in netstat-after.txt${NC}"
    fi
else
    echo -e "${RED}✗ netstat-after.txt not found at /opt/course/15/netstat-after.txt${NC}"
    PASS=false
fi

echo ""

# Live checks on node
echo "Part 6: Live Verification"
echo "──────────────────────────"

# Check current socket ownership
CURRENT_SOCKET=$(ssh $NODE "ls -la /run/containerd/containerd.sock" 2>/dev/null)
if echo "$CURRENT_SOCKET" | grep -q "root.*root"; then
    echo -e "${GREEN}✓ Socket currently owned by root:root${NC}"
else
    echo -e "${RED}✗ Socket is NOT currently owned by root:root${NC}"
    echo "$CURRENT_SOCKET"
    PASS=false
fi

# Check current config
if ssh $NODE "grep -qi 'tcp_address' /etc/containerd/config.toml" 2>/dev/null; then
    echo -e "${RED}✗ tcp_address still in /etc/containerd/config.toml${NC}"
    PASS=false
else
    echo -e "${GREEN}✓ tcp_address removed from current config${NC}"
fi

# Check TCP port
TCP_CHECK=$(ssh $NODE "ss -tlnp | grep ':10000'" 2>/dev/null || echo "")
if [ -z "$TCP_CHECK" ]; then
    echo -e "${GREEN}✓ Containerd is NOT listening on TCP port 10000${NC}"
else
    echo -e "${RED}✗ Containerd is still listening on TCP port 10000${NC}"
    PASS=false
fi

# Check containerd running
if ssh $NODE "systemctl is-active containerd" 2>/dev/null | grep -q "active"; then
    echo -e "${GREEN}✓ containerd daemon is running${NC}"
else
    echo -e "${RED}✗ containerd daemon is NOT running${NC}"
    PASS=false
fi

echo ""

# Check cluster health
echo "Part 7: Cluster Health"
echo "───────────────────────"
if kubectl get nodes 2>/dev/null | grep -q "Ready"; then
    echo -e "${GREEN}✓ Cluster nodes are Ready${NC}"
    kubectl get nodes
else
    echo -e "${RED}✗ Cluster nodes are not Ready${NC}"
    PASS=false
fi

echo ""
echo "=============================================="
echo "Summary"
echo "=============================================="

if $PASS; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed. Review the issues above.${NC}"
    exit 1
fi
