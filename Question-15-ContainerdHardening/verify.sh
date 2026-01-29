#!/bin/bash
# Verify Question 15 - Containerd Security Hardening

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Containerd Security Hardening..."
echo ""

# Check socket permissions file
echo "Part 1: Socket Permissions"
echo "──────────────────────────"
if [ -f "/opt/course/15/socket-permissions.txt" ]; then
    echo -e "${GREEN}✓ socket-permissions.txt exists${NC}"

    if [ -s "/opt/course/15/socket-permissions.txt" ]; then
        echo -e "${GREEN}✓ socket-permissions.txt is not empty${NC}"

        if grep -q "containerd.sock" /opt/course/15/socket-permissions.txt; then
            echo -e "${GREEN}✓ File contains containerd.sock reference${NC}"
        else
            echo -e "${YELLOW}⚠ Could not verify socket reference${NC}"
        fi

        # Check for root ownership
        if grep -q "root.*root" /opt/course/15/socket-permissions.txt; then
            echo -e "${GREEN}✓ Socket appears to be owned by root${NC}"
        else
            echo -e "${YELLOW}⚠ Socket may not be owned by root${NC}"
        fi
    else
        echo -e "${RED}✗ socket-permissions.txt is empty${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ socket-permissions.txt not found at /opt/course/15/socket-permissions.txt${NC}"
    PASS=false
fi

echo ""

# Check containerd grpc config file
echo "Part 2: Containerd gRPC Configuration"
echo "──────────────────────────────────────"
if [ -f "/opt/course/15/containerd-grpc.txt" ]; then
    echo -e "${GREEN}✓ containerd-grpc.txt exists${NC}"

    if [ -s "/opt/course/15/containerd-grpc.txt" ]; then
        echo -e "${GREEN}✓ containerd-grpc.txt is not empty${NC}"

        # Check for unix socket (good) vs TCP (bad)
        if grep -q "tcp://" /opt/course/15/containerd-grpc.txt; then
            echo -e "${YELLOW}⚠ TCP listener found - this is a security concern${NC}"
        else
            echo -e "${GREEN}✓ No TCP listeners configured${NC}"
        fi
    else
        echo -e "${RED}✗ containerd-grpc.txt is empty${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ containerd-grpc.txt not found at /opt/course/15/containerd-grpc.txt${NC}"
    PASS=false
fi

echo ""

# Check container groups file
echo "Part 3: Container Groups"
echo "─────────────────────────"
if [ -f "/opt/course/15/container-groups.txt" ]; then
    echo -e "${GREEN}✓ container-groups.txt exists${NC}"
    echo "  Content: $(cat /opt/course/15/container-groups.txt | head -3)"
else
    echo -e "${RED}✗ container-groups.txt not found at /opt/course/15/container-groups.txt${NC}"
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
