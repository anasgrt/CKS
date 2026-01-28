#!/bin/bash
# Verify Question 13 - Kubelet Security Configuration

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Kubelet Security Configuration..."
echo ""

# Check output files
echo "Checking output files..."

if [ -f "/opt/course/13/kubelet-before.yaml" ]; then
    echo -e "${GREEN}✓ kubelet-before.yaml saved${NC}"
else
    echo -e "${RED}✗ kubelet-before.yaml not found at /opt/course/13/kubelet-before.yaml${NC}"
    PASS=false
fi

if [ -f "/opt/course/13/kubelet-after.yaml" ]; then
    echo -e "${GREEN}✓ kubelet-after.yaml saved${NC}"

    # Check anonymous auth is disabled
    if grep -A2 "anonymous:" /opt/course/13/kubelet-after.yaml | grep -q "enabled: false"; then
        echo -e "${GREEN}✓ Anonymous authentication is disabled${NC}"
    else
        echo -e "${RED}✗ Anonymous authentication should be disabled${NC}"
        PASS=false
    fi

    # Check webhook auth is enabled
    if grep -A2 "webhook:" /opt/course/13/kubelet-after.yaml | grep -q "enabled: true"; then
        echo -e "${GREEN}✓ Webhook authentication is enabled${NC}"
    else
        echo -e "${YELLOW}⚠ Webhook authentication should be enabled${NC}"
    fi

    # Check authorization mode is Webhook
    if grep -q "mode: Webhook" /opt/course/13/kubelet-after.yaml; then
        echo -e "${GREEN}✓ Authorization mode is Webhook${NC}"
    else
        echo -e "${RED}✗ Authorization mode should be Webhook${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ kubelet-after.yaml not found at /opt/course/13/kubelet-after.yaml${NC}"
    PASS=false
fi

# Check node status
echo ""
echo "Checking node status..."
READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c "Ready" || echo "0")
if [ "$READY_NODES" -ge 1 ]; then
    echo -e "${GREEN}✓ Node(s) are in Ready state${NC}"
else
    echo -e "${RED}✗ Check that nodes are in Ready state${NC}"
    PASS=false
fi

echo ""
echo "=============================================="
echo "Summary"
echo "=============================================="

if $PASS; then
    echo -e "${GREEN}Output files verified!${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed.${NC}"
    exit 1
fi
