#!/bin/bash
# Verify Question 09 - Configure Kubernetes Auditing

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Kubernetes Auditing Configuration..."
echo ""

# Check audit policy file exists
echo "Checking audit policy file..."
if [ -f "/opt/course/09/audit-policy.yaml" ]; then
    echo -e "${GREEN}✓ audit-policy.yaml saved to /opt/course/09/${NC}"

    # Check for secrets rule
    if grep -qi "secrets" /opt/course/09/audit-policy.yaml; then
        echo -e "${GREEN}✓ Policy includes secrets rule${NC}"
    else
        echo -e "${RED}✗ Policy should include secrets rule${NC}"
        PASS=false
    fi

    # Check for configmaps rule
    if grep -qi "configmaps" /opt/course/09/audit-policy.yaml; then
        echo -e "${GREEN}✓ Policy includes configmaps rule${NC}"
    else
        echo -e "${RED}✗ Policy should include configmaps rule${NC}"
        PASS=false
    fi

    # Check for namespaces rule
    if grep -qi "namespaces" /opt/course/09/audit-policy.yaml; then
        echo -e "${GREEN}✓ Policy includes namespaces rule${NC}"
    else
        echo -e "${RED}✗ Policy should include namespaces rule${NC}"
        PASS=false
    fi

    # Check for Metadata level
    if grep -qi "Metadata" /opt/course/09/audit-policy.yaml; then
        echo -e "${GREEN}✓ Policy uses Metadata level${NC}"
    else
        echo -e "${YELLOW}⚠ Policy should use Metadata level for some rules${NC}"
    fi

    # Check for RequestResponse level
    if grep -qi "RequestResponse" /opt/course/09/audit-policy.yaml; then
        echo -e "${GREEN}✓ Policy uses RequestResponse level${NC}"
    else
        echo -e "${YELLOW}⚠ Policy should use RequestResponse level for namespaces${NC}"
    fi
else
    echo -e "${RED}✗ audit-policy.yaml not found at /opt/course/09/audit-policy.yaml${NC}"
    PASS=false
fi

# Check API server is running
echo ""
echo "Checking API server status..."
API_SERVER=$(kubectl get pods -n kube-system -l component=kube-apiserver -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Unknown")
if [ "$API_SERVER" == "Running" ]; then
    echo -e "${GREEN}✓ API server is running${NC}"
else
    echo -e "${RED}✗ API server status: $API_SERVER${NC}"
    PASS=false
fi

# Check cluster health
NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c "Ready" || echo "0")
if [ "$NODES" -ge 1 ]; then
    echo -e "${GREEN}✓ Cluster is healthy ($NODES nodes ready)${NC}"
else
    echo -e "${RED}✗ Cluster health check failed${NC}"
    PASS=false
fi

echo ""
echo "=============================================="
echo "Configuration Checklist:"
echo "=============================================="
echo ""
echo "[ ] Created /etc/kubernetes/audit/policy.yaml"
echo "[ ] Added --audit-policy-file flag"
echo "[ ] Added --audit-log-path flag"
echo "[ ] Added --audit-log-maxage=2"
echo "[ ] Added --audit-log-maxbackup=10"
echo "[ ] Added volume for audit policy"
echo "[ ] Added volumeMount for audit policy"
echo "[ ] Added volume for audit logs"
echo "[ ] Added volumeMount for audit logs"
echo ""

if $PASS; then
    echo -e "${GREEN}Output files verified!${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed.${NC}"
    exit 1
fi
