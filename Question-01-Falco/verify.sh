#!/bin/bash
# Verify Question 01 - Falco Runtime Security Detection

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Falco Runtime Security Detection..."
echo ""

# Check if ollama deployment is scaled to 0
echo "Checking deployment scaling..."
OLLAMA_REPLICAS=$(kubectl get deployment ollama -n apps -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "not found")

if [ "$OLLAMA_REPLICAS" == "0" ]; then
    echo -e "${GREEN}✓ Deployment 'ollama' is scaled to 0 replicas${NC}"
else
    echo -e "${RED}✗ Deployment 'ollama' should be scaled to 0 (current: $OLLAMA_REPLICAS)${NC}"
    PASS=false
fi

# Check nvidia-gpu is still running
NVIDIA_REPLICAS=$(kubectl get deployment nvidia-gpu -n apps -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
if [ "$NVIDIA_REPLICAS" -ge 1 ]; then
    echo -e "${GREEN}✓ Deployment 'nvidia-gpu' is still running${NC}"
else
    echo -e "${RED}✗ Deployment 'nvidia-gpu' should still be running${NC}"
    PASS=false
fi

# Check cpu is still running
CPU_REPLICAS=$(kubectl get deployment cpu -n apps -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
if [ "$CPU_REPLICAS" -ge 1 ]; then
    echo -e "${GREEN}✓ Deployment 'cpu' is still running${NC}"
else
    echo -e "${RED}✗ Deployment 'cpu' should still be running${NC}"
    PASS=false
fi

echo ""
echo "Checking output files..."

# Check pod-name.txt exists and contains ollama pod name
if [ -f "/opt/course/01/pod-name.txt" ]; then
    echo -e "${GREEN}✓ pod-name.txt exists${NC}"

    POD_NAME=$(cat /opt/course/01/pod-name.txt | tr -d '[:space:]')
    if [[ "$POD_NAME" == *"ollama"* ]]; then
        echo -e "${GREEN}✓ Correct pod name identified (contains 'ollama')${NC}"
    else
        echo -e "${RED}✗ Pod name should contain 'ollama' (found: $POD_NAME)${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ pod-name.txt not found at /opt/course/01/pod-name.txt${NC}"
    PASS=false
fi

# Check falco-alert.txt exists
if [ -f "/opt/course/01/falco-alert.txt" ]; then
    echo -e "${GREEN}✓ falco-alert.txt exists${NC}"

    # Check if it contains relevant content
    if grep -qi "mem\|memory\|device\|ollama" /opt/course/01/falco-alert.txt 2>/dev/null; then
        echo -e "${GREEN}✓ falco-alert.txt contains relevant alert information${NC}"
    else
        echo -e "${YELLOW}⚠ falco-alert.txt should contain memory/device related alert${NC}"
    fi
else
    echo -e "${RED}✗ falco-alert.txt not found at /opt/course/01/falco-alert.txt${NC}"
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
