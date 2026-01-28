#!/bin/bash
# Verify Question 11 - Pod Security Admission

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Pod Security Admission task..."
echo ""

# Check non-compliant pods are deleted
echo "Checking pod status..."

# Check hostnetwork-pod is deleted
if kubectl get pod hostnetwork-pod -n team-blue &>/dev/null; then
    echo -e "${RED}✗ hostnetwork-pod should be deleted${NC}"
    PASS=false
else
    echo -e "${GREEN}✓ hostnetwork-pod has been deleted${NC}"
fi

# Check root-pod is deleted
if kubectl get pod root-pod -n team-blue &>/dev/null; then
    echo -e "${RED}✗ root-pod should be deleted${NC}"
    PASS=false
else
    echo -e "${GREEN}✓ root-pod has been deleted${NC}"
fi

# Check escalation-pod is deleted
if kubectl get pod escalation-pod -n team-blue &>/dev/null; then
    echo -e "${RED}✗ escalation-pod should be deleted${NC}"
    PASS=false
else
    echo -e "${GREEN}✓ escalation-pod has been deleted${NC}"
fi

# Check compliant-pod is still running
if kubectl get pod compliant-pod -n team-blue &>/dev/null; then
    echo -e "${GREEN}✓ compliant-pod is still running${NC}"
else
    echo -e "${RED}✗ compliant-pod should still be running!${NC}"
    PASS=false
fi

# Check output files
echo ""
echo "Checking output files..."

if [ -f "/opt/course/11/violations.txt" ]; then
    echo -e "${GREEN}✓ violations.txt saved${NC}"
else
    echo -e "${RED}✗ violations.txt not found at /opt/course/11/violations.txt${NC}"
    PASS=false
fi

if [ -f "/opt/course/11/deleted-pods.txt" ]; then
    echo -e "${GREEN}✓ deleted-pods.txt saved${NC}"

    # Verify content
    if grep -qi "hostnetwork\|root\|escalation" /opt/course/11/deleted-pods.txt 2>/dev/null; then
        echo -e "${GREEN}✓ deleted-pods.txt contains expected pod names${NC}"
    else
        echo -e "${YELLOW}⚠ Verify deleted-pods.txt contains the correct pod names${NC}"
    fi
else
    echo -e "${RED}✗ deleted-pods.txt not found at /opt/course/11/deleted-pods.txt${NC}"
    PASS=false
fi

if [ -f "/opt/course/11/command.txt" ]; then
    echo -e "${GREEN}✓ command.txt saved${NC}"
else
    echo -e "${RED}✗ command.txt not found at /opt/course/11/command.txt${NC}"
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
    echo -e "${RED}Some checks failed.${NC}"
    exit 1
fi
