#!/bin/bash
# Verify Question 10 - ImagePolicyWebhook Admission Controller

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Verifying ImagePolicyWebhook Configuration..."
echo ""

# ══════════════════════════════════════════════════════════════════════════════
# Check admission_config.yaml in /etc/kubernetes/epconfig/
# ══════════════════════════════════════════════════════════════════════════════
echo "1. Checking /etc/kubernetes/epconfig/admission_config.yaml..."
if [ -f "/etc/kubernetes/epconfig/admission_config.yaml" ]; then
    # Check defaultAllow is false (not true)
    if grep -q "defaultAllow: false" /etc/kubernetes/epconfig/admission_config.yaml; then
        echo -e "${GREEN}   ✓ defaultAllow is correctly set to false (fail-closed)${NC}"
    elif grep -q "defaultAllow: true" /etc/kubernetes/epconfig/admission_config.yaml; then
        echo -e "${RED}   ✗ defaultAllow is still true (INSECURE - should be false)${NC}"
        PASS=false
    else
        echo -e "${RED}   ✗ defaultAllow setting not found${NC}"
        PASS=false
    fi
else
    echo -e "${RED}   ✗ admission_config.yaml not found${NC}"
    PASS=false
fi

# ══════════════════════════════════════════════════════════════════════════════
# Check kubeconfig.yaml in /etc/kubernetes/epconfig/
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "2. Checking /etc/kubernetes/epconfig/kubeconfig.yaml..."
if [ -f "/etc/kubernetes/epconfig/kubeconfig.yaml" ]; then
    # Check server URL is correct (not placeholder)
    if grep -q "server: https://image-policy-webhook.default.svc:443/image_policy" /etc/kubernetes/epconfig/kubeconfig.yaml; then
        echo -e "${GREEN}   ✓ Server URL is correctly configured${NC}"
    elif grep -q "EDIT_ME" /etc/kubernetes/epconfig/kubeconfig.yaml; then
        echo -e "${RED}   ✗ Server URL still contains placeholder (EDIT_ME)${NC}"
        PASS=false
    else
        echo -e "${YELLOW}   ⚠ Server URL may not be correct (expected: https://image-policy-webhook.default.svc:443/image_policy)${NC}"
    fi

    # Check current-context is set
    if grep -q 'current-context: default' /etc/kubernetes/epconfig/kubeconfig.yaml; then
        echo -e "${GREEN}   ✓ current-context is correctly set to default${NC}"
    elif grep -q 'current-context: ""' /etc/kubernetes/epconfig/kubeconfig.yaml; then
        echo -e "${RED}   ✗ current-context is empty (should be 'default')${NC}"
        PASS=false
    else
        echo -e "${YELLOW}   ⚠ current-context may not be set correctly${NC}"
    fi
else
    echo -e "${RED}   ✗ kubeconfig.yaml not found${NC}"
    PASS=false
fi

# ══════════════════════════════════════════════════════════════════════════════
# Check saved copies in /opt/course/10/
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "3. Checking saved copies in /opt/course/10/..."
if [ -f "/opt/course/10/admission_config.yaml" ]; then
    echo -e "${GREEN}   ✓ admission_config.yaml saved to /opt/course/10/${NC}"
    if grep -q "defaultAllow: false" /opt/course/10/admission_config.yaml; then
        echo -e "${GREEN}   ✓ Saved copy has defaultAllow: false${NC}"
    else
        echo -e "${RED}   ✗ Saved copy does not have defaultAllow: false${NC}"
        PASS=false
    fi
else
    echo -e "${RED}   ✗ admission_config.yaml not found at /opt/course/10/${NC}"
    PASS=false
fi

if [ -f "/opt/course/10/kubeconfig.yaml" ]; then
    echo -e "${GREEN}   ✓ kubeconfig.yaml saved to /opt/course/10/${NC}"
else
    echo -e "${RED}   ✗ kubeconfig.yaml not found at /opt/course/10/${NC}"
    PASS=false
fi

# ══════════════════════════════════════════════════════════════════════════════
# Check API server configuration
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "4. Checking kube-apiserver configuration..."

# Check if ImagePolicyWebhook is enabled
if grep -q "ImagePolicyWebhook" /etc/kubernetes/manifests/kube-apiserver.yaml; then
    echo -e "${GREEN}   ✓ ImagePolicyWebhook is in enable-admission-plugins${NC}"
else
    echo -e "${RED}   ✗ ImagePolicyWebhook not found in enable-admission-plugins${NC}"
    PASS=false
fi

# Check admission-control-config-file flag
if grep -q "admission-control-config-file=/etc/kubernetes/epconfig/admission_config.yaml" /etc/kubernetes/manifests/kube-apiserver.yaml; then
    echo -e "${GREEN}   ✓ admission-control-config-file flag is set correctly${NC}"
else
    echo -e "${RED}   ✗ admission-control-config-file flag not found or incorrect${NC}"
    PASS=false
fi

# Check volume mount
if grep -q "/etc/kubernetes/epconfig" /etc/kubernetes/manifests/kube-apiserver.yaml && grep -q "name: epconfig" /etc/kubernetes/manifests/kube-apiserver.yaml; then
    echo -e "${GREEN}   ✓ epconfig volume and volumeMount configured${NC}"
else
    echo -e "${YELLOW}   ⚠ epconfig volume/volumeMount may not be configured${NC}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Check API server is running
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "5. Checking API server status..."
API_SERVER=$(kubectl get pods -n kube-system -l component=kube-apiserver -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Unknown")
if [ "$API_SERVER" == "Running" ]; then
    echo -e "${GREEN}   ✓ API server is running${NC}"
else
    echo -e "${RED}   ✗ API server status: $API_SERVER${NC}"
    PASS=false
fi

# ══════════════════════════════════════════════════════════════════════════════
# Summary
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "=============================================="
if $PASS; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo "=============================================="
    exit 0
else
    echo -e "${RED}✗ Some checks failed.${NC}"
    echo "=============================================="
    echo ""
    echo "Configuration Checklist:"
    echo "[ ] Fixed defaultAllow: false in admission_config.yaml"
    echo "[ ] Fixed server URL in kubeconfig.yaml"
    echo "[ ] Fixed current-context: default in kubeconfig.yaml"
    echo "[ ] Added ImagePolicyWebhook to --enable-admission-plugins"
    echo "[ ] Set --admission-control-config-file"
    echo "[ ] Added volume and volumeMount for epconfig"
    echo "[ ] Saved copies to /opt/course/10/"
    exit 1
fi
