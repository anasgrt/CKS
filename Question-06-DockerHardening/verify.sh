#!/bin/bash
# Verify Question 06 - Docker Daemon Security Hardening

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Docker Daemon Hardening..."
echo ""

# Check output files exist
echo "Checking output files..."

if [ -f "/opt/course/06/socket-before.txt" ]; then
    echo -e "${GREEN}✓ socket-before.txt exists${NC}"
else
    echo -e "${RED}✗ socket-before.txt not found at /opt/course/06/socket-before.txt${NC}"
    PASS=false
fi

if [ -f "/opt/course/06/socket-after.txt" ]; then
    echo -e "${GREEN}✓ socket-after.txt exists${NC}"

    # Check if socket is owned by root group
    if grep -q "root" /opt/course/06/socket-after.txt 2>/dev/null; then
        echo -e "${GREEN}✓ Socket appears to be owned by root group${NC}"
    else
        echo -e "${YELLOW}⚠ Verify socket is owned by root group${NC}"
    fi
else
    echo -e "${RED}✗ socket-after.txt not found at /opt/course/06/socket-after.txt${NC}"
    PASS=false
fi

if [ -f "/opt/course/06/daemon.json" ]; then
    echo -e "${GREEN}✓ daemon.json exists${NC}"

    # Check daemon.json doesn't have TCP host
    if grep -qi "tcp://" /opt/course/06/daemon.json 2>/dev/null; then
        echo -e "${RED}✗ daemon.json should not contain tcp:// listeners${NC}"
        PASS=false
    else
        echo -e "${GREEN}✓ No TCP listeners in daemon.json${NC}"
    fi
else
    echo -e "${RED}✗ daemon.json not found at /opt/course/06/daemon.json${NC}"
    PASS=false
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
    echo -e "${GREEN}Output files verified!${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed.${NC}"
    exit 1
fi
