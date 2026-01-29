#!/bin/bash
# Verify Question 15 - Containerd Security Hardening

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Containerd Security Hardening..."
echo ""

# Check socket-before.txt
echo "Part 1: Socket Permissions Before"
echo "──────────────────────────────────"
if [ -f "/opt/course/15/socket-before.txt" ]; then
    echo -e "${GREEN}✓ socket-before.txt exists${NC}"

    if [ -s "/opt/course/15/socket-before.txt" ]; then
        echo -e "${GREEN}✓ socket-before.txt is not empty${NC}"
    else
        echo -e "${RED}✗ socket-before.txt is empty${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ socket-before.txt not found at /opt/course/15/socket-before.txt${NC}"
    PASS=false
fi

echo ""

# Check socket-after.txt
echo "Part 2: Socket Permissions After"
echo "─────────────────────────────────"
if [ -f "/opt/course/15/socket-after.txt" ]; then
    echo -e "${GREEN}✓ socket-after.txt exists${NC}"

    if [ -s "/opt/course/15/socket-after.txt" ]; then
        echo -e "${GREEN}✓ socket-after.txt is not empty${NC}"

        if grep -q "containerd.sock" /opt/course/15/socket-after.txt; then
            echo -e "${GREEN}✓ File contains containerd.sock reference${NC}"
        else
            echo -e "${YELLOW}⚠ Could not verify socket reference${NC}"
        fi

        # Check for root ownership
        if grep -q "root.*root" /opt/course/15/socket-after.txt; then
            echo -e "${GREEN}✓ Socket is owned by root:root${NC}"
        else
            echo -e "${RED}✗ Socket should be owned by root:root${NC}"
            PASS=false
        fi
    else
        echo -e "${RED}✗ socket-after.txt is empty${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ socket-after.txt not found at /opt/course/15/socket-after.txt${NC}"
    PASS=false
fi

echo ""

# Check config.toml
echo "Part 3: Containerd Configuration"
echo "─────────────────────────────────"
if [ -f "/opt/course/15/config.toml" ]; then
    echo -e "${GREEN}✓ config.toml exists${NC}"

    if [ -s "/opt/course/15/config.toml" ]; then
        echo -e "${GREEN}✓ config.toml is not empty${NC}"

        # Check for TCP listeners (bad)
        if grep -q "tcp://" /opt/course/15/config.toml; then
            echo -e "${RED}✗ TCP listener found - this is a security concern${NC}"
            PASS=false
        else
            echo -e "${GREEN}✓ No TCP listeners configured${NC}"
        fi
    else
        echo -e "${RED}✗ config.toml is empty${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ config.toml not found at /opt/course/15/config.toml${NC}"
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
