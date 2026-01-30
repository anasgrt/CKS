#!/bin/bash
# Verify Question 06 - Docker Daemon Security Hardening

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Docker Daemon Hardening..."
echo ""

# Determine which node was configured
NODE_NAME="node01"
if ! kubectl get node $NODE_NAME &>/dev/null; then
    NODE_NAME=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
fi

if [ -z "$NODE_NAME" ]; then
    echo -e "${RED}✗ No worker nodes found in cluster${NC}"
    exit 1
fi

echo "Checking configuration on node: $NODE_NAME"
echo ""

# Check output files exist on the node
echo "Checking output files..."

if ssh $NODE_NAME "test -f /opt/course/06/socket-before.txt" 2>/dev/null; then
    echo -e "${GREEN}✓ socket-before.txt exists on $NODE_NAME${NC}"
else
    echo -e "${RED}✗ socket-before.txt not found at /opt/course/06/socket-before.txt on $NODE_NAME${NC}"
    PASS=false
fi

if ssh $NODE_NAME "test -f /opt/course/06/socket-after.txt" 2>/dev/null; then
    echo -e "${GREEN}✓ socket-after.txt exists on $NODE_NAME${NC}"

    # Check if socket is owned by root group
    if ssh $NODE_NAME "grep -q 'root root' /opt/course/06/socket-after.txt" 2>/dev/null; then
        echo -e "${GREEN}✓ Socket is owned by root:root${NC}"
    else
        echo -e "${YELLOW}⚠ Socket ownership may not be root:root${NC}"
    fi
else
    echo -e "${RED}✗ socket-after.txt not found at /opt/course/06/socket-after.txt on $NODE_NAME${NC}"
    PASS=false
fi

if ssh $NODE_NAME "test -f /opt/course/06/daemon.json" 2>/dev/null; then
    echo -e "${GREEN}✓ daemon.json exists on $NODE_NAME${NC}"

    # Check daemon.json doesn't have TCP host
    if ssh $NODE_NAME "grep -qi 'tcp://' /opt/course/06/daemon.json" 2>/dev/null; then
        echo -e "${RED}✗ daemon.json should not contain tcp:// listeners${NC}"
        PASS=false
    else
        echo -e "${GREEN}✓ No TCP listeners in daemon.json${NC}"
    fi

    # Check if group is set to root
    if ssh $NODE_NAME "grep -q '\"group\".*:.*\"root\"' /opt/course/06/daemon.json" 2>/dev/null; then
        echo -e "${GREEN}✓ Docker group set to 'root' in daemon.json${NC}"
    else
        echo -e "${YELLOW}⚠ Docker group should be set to 'root' in daemon.json${NC}"
    fi
else
    echo -e "${RED}✗ daemon.json not found at /opt/course/06/daemon.json on $NODE_NAME${NC}"
    PASS=false
fi

echo ""
echo "Checking user 'developer' groups..."
if ssh $NODE_NAME "id developer" 2>/dev/null | grep -q "docker"; then
    echo -e "${RED}✗ User 'developer' is still in docker group${NC}"
    PASS=false
else
    echo -e "${GREEN}✓ User 'developer' is NOT in docker group${NC}"
fi

echo ""
echo "=============================================="
echo "Checklist:"
echo "=============================================="
echo ""
echo "[ ] User 'developer' removed from docker group"
echo "[ ] Docker socket owned by root group"
echo "[ ] No TCP listeners in Docker daemon"
echo "[ ] Docker daemon restarted"
echo "[ ] Kubernetes cluster healthy"
echo ""

if $PASS; then
    echo -e "${GREEN}All checks passed!${NC}"
    echo ""
    echo "Verification complete on $NODE_NAME"
    exit 0
else
    echo -e "${RED}Some checks failed.${NC}"
    exit 1
fi
