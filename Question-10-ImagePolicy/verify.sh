#!/bin/bash
# Verify Question 10 - ImagePolicyWebhook Admission Controller

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking ImagePolicyWebhook Configuration..."
echo ""

# Check admission-config.yaml
echo "Checking admission configuration..."
if [ -f "/opt/course/10/admission-config.yaml" ]; then
    echo -e "${GREEN}✓ admission-config.yaml saved${NC}"

    # Check for ImagePolicyWebhook plugin
    if grep -qi "ImagePolicyWebhook" /opt/course/10/admission-config.yaml; then
        echo -e "${GREEN}✓ Contains ImagePolicyWebhook configuration${NC}"
    else
        echo -e "${RED}✗ Should contain ImagePolicyWebhook configuration${NC}"
        PASS=false
    fi

    # Check defaultAllow is false
    if grep -qi "defaultAllow.*false" /opt/course/10/admission-config.yaml; then
        echo -e "${GREEN}✓ defaultAllow is set to false${NC}"
    else
        echo -e "${RED}✗ defaultAllow should be false (fail-closed)${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ admission-config.yaml not found at /opt/course/10/admission-config.yaml${NC}"
    PASS=false
fi

# Check kubeconfig.yaml
echo ""
echo "Checking kubeconfig..."
if [ -f "/opt/course/10/kubeconfig.yaml" ]; then
    echo -e "${GREEN}✓ kubeconfig.yaml saved${NC}"

    # Check server URL
    if grep -qi "image-policy-webhook\|server:" /opt/course/10/kubeconfig.yaml; then
        echo -e "${GREEN}✓ Contains server configuration${NC}"
    else
        echo -e "${YELLOW}⚠ Should contain webhook server URL${NC}"
    fi
else
    echo -e "${RED}✗ kubeconfig.yaml not found at /opt/course/10/kubeconfig.yaml${NC}"
    PASS=false
fi

# Check API server is running
echo ""
echo "Checking API server status..."
API_SERVER=$(kubectl get pods -n kube-system -l component=kube-apiserver -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Unknown")
if [ "$API_SERVER" == "Running" ]; then
    echo -e "${GREEN}✓ API server is running${NC}"
else
    echo -e "${YELLOW}⚠ API server status: $API_SERVER${NC}"
fi

echo ""
echo "=============================================="
echo "Configuration Checklist:"
echo "=============================================="
echo ""
echo "[ ] Added ImagePolicyWebhook to --enable-admission-plugins"
echo "[ ] Set --admission-control-config-file"
echo "[ ] Set defaultAllow: false in admission config"
echo "[ ] Configured kubeconfig with webhook server URL"
echo "[ ] Added volumes and volumeMounts to API server"
echo ""

if $PASS; then
    echo -e "${GREEN}Output files verified!${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed.${NC}"
    exit 1
fi
