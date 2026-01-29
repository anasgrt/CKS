#!/bin/bash
# Verify Question 01 - Falco Runtime Security Detection

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Falco Runtime Security Detection..."
echo ""

# First, verify Falco is running (prerequisite check)
echo "Prerequisite Checks:"
echo "───────────────────"
if pgrep -x falco > /dev/null || systemctl is-active --quiet falco 2>/dev/null; then
    echo -e "${GREEN}✓ Falco is running${NC}"
else
    echo -e "${YELLOW}⚠ Falco may not be running - some checks may fail${NC}"
fi
echo ""

# Check if ollama deployment is scaled to 0
echo "Deployment Checks:"
echo "──────────────────"
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
echo "Output File Checks:"
echo "───────────────────"

# Check pod-name.txt exists and contains ollama pod name
if [ -f "/opt/course/01/pod-name.txt" ]; then
    echo -e "${GREEN}✓ pod-name.txt exists${NC}"

    POD_NAME=$(cat /opt/course/01/pod-name.txt | tr -d '[:space:]')
    if [[ "$POD_NAME" == *"ollama"* ]]; then
        echo -e "${GREEN}✓ Correct pod name identified (contains 'ollama'): $POD_NAME${NC}"
    else
        echo -e "${RED}✗ Pod name should contain 'ollama' (found: $POD_NAME)${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ pod-name.txt not found at /opt/course/01/pod-name.txt${NC}"
    PASS=false
fi

# Check falco-alert.txt exists and has meaningful content
if [ -f "/opt/course/01/falco-alert.txt" ]; then
    echo -e "${GREEN}✓ falco-alert.txt exists${NC}"

    ALERT_CONTENT=$(cat /opt/course/01/falco-alert.txt)

    # Check if it contains relevant Falco output indicators
    if echo "$ALERT_CONTENT" | grep -qiE "mem|memory|device|ollama|Notice|Warning"; then
        echo -e "${GREEN}✓ falco-alert.txt contains relevant alert information${NC}"

        # Extra credit: Check if it looks like an actual Falco log line
        if echo "$ALERT_CONTENT" | grep -qE "[0-9]{2}:[0-9]{2}:[0-9]{2}|container=|container_name=|pod=|ns="; then
            echo -e "${GREEN}✓ Alert appears to be a valid Falco log entry${NC}"
        else
            echo -e "${YELLOW}⚠ Alert may not be a direct Falco log line (acceptable if summary)${NC}"
        fi
    else
        echo -e "${RED}✗ falco-alert.txt should contain memory/device related alert or 'ollama' reference${NC}"
        echo -e "${YELLOW}  Content: $ALERT_CONTENT${NC}"
        PASS=false
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
