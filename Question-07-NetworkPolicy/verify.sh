#!/bin/bash
# Verify Question 07 - Network Policy

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Network Policies..."
echo ""

# Check deny-all-ingress policy in prod namespace
echo "Checking deny-all-ingress in prod namespace..."
if kubectl get networkpolicy deny-all-ingress -n prod &>/dev/null; then
    echo -e "${GREEN}✓ NetworkPolicy 'deny-all-ingress' exists in prod${NC}"

    # Check it applies to all pods (empty podSelector)
    POD_SELECTOR=$(kubectl get networkpolicy deny-all-ingress -n prod -o jsonpath='{.spec.podSelector}' 2>/dev/null)
    if [ "$POD_SELECTOR" == "{}" ] || [ -z "$POD_SELECTOR" ]; then
        echo -e "${GREEN}✓ Policy applies to all pods (empty podSelector)${NC}"
    else
        echo -e "${YELLOW}⚠ podSelector should be empty to apply to all pods${NC}"
    fi

    # Check it has Ingress policy type
    POLICY_TYPES=$(kubectl get networkpolicy deny-all-ingress -n prod -o jsonpath='{.spec.policyTypes[*]}' 2>/dev/null)
    if [[ "$POLICY_TYPES" == *"Ingress"* ]]; then
        echo -e "${GREEN}✓ Policy includes Ingress type${NC}"
    else
        echo -e "${RED}✗ Policy should include Ingress type${NC}"
        PASS=false
    fi

    # Check ingress is empty (deny all)
    INGRESS=$(kubectl get networkpolicy deny-all-ingress -n prod -o jsonpath='{.spec.ingress}' 2>/dev/null)
    if [ -z "$INGRESS" ] || [ "$INGRESS" == "null" ]; then
        echo -e "${GREEN}✓ Ingress is empty (denies all)${NC}"
    else
        echo -e "${YELLOW}⚠ Ingress should be empty or not specified to deny all${NC}"
    fi
else
    echo -e "${RED}✗ NetworkPolicy 'deny-all-ingress' not found in prod namespace${NC}"
    PASS=false
fi

echo ""
echo "Checking allow-from-prod in data namespace..."
if kubectl get networkpolicy allow-from-prod -n data &>/dev/null; then
    echo -e "${GREEN}✓ NetworkPolicy 'allow-from-prod' exists in data${NC}"

    # Check if policy has both namespaceSelector AND podSelector in the same from block (AND condition)
    # This is crucial - they must be in the same array element for AND logic
    POLICY_JSON=$(kubectl get networkpolicy allow-from-prod -n data -o json 2>/dev/null)

    # Check namespace selector exists
    NS_SELECTOR=$(echo "$POLICY_JSON" | grep -o '"namespaceSelector"' | head -1)
    if [ -n "$NS_SELECTOR" ]; then
        echo -e "${GREEN}✓ Has namespaceSelector${NC}"
    else
        echo -e "${RED}✗ Should have namespaceSelector for prod namespace${NC}"
        PASS=false
    fi

    # Check pod selector exists in the from block
    POD_SELECTOR=$(echo "$POLICY_JSON" | grep -o '"podSelector"' | wc -l)
    if [ "$POD_SELECTOR" -ge 2 ]; then  # One for spec.podSelector, one for ingress.from[].podSelector
        echo -e "${GREEN}✓ Has podSelector in ingress from block${NC}"
    else
        echo -e "${YELLOW}⚠ Should have podSelector for env=prod in the from block${NC}"
    fi

    # Verify it's an AND condition (namespaceSelector and podSelector in same object)
    # Count the number of 'from' array elements - should be 1 for AND condition
    FROM_ELEMENTS=$(echo "$POLICY_JSON" | grep -c '"from"' 2>/dev/null || echo "0")
    if [ "$FROM_ELEMENTS" -ge 1 ]; then
        echo -e "${GREEN}✓ Has ingress from rules configured${NC}"
    fi
else
    echo -e "${RED}✗ NetworkPolicy 'allow-from-prod' not found in data namespace${NC}"
    PASS=false
fi

# Check output files
echo ""
echo "Checking output files..."

if [ -f "/opt/course/07/deny-all-ingress.yaml" ]; then
    echo -e "${GREEN}✓ deny-all-ingress.yaml saved${NC}"
else
    echo -e "${RED}✗ deny-all-ingress.yaml not found at /opt/course/07/deny-all-ingress.yaml${NC}"
    PASS=false
fi

if [ -f "/opt/course/07/allow-from-prod.yaml" ]; then
    echo -e "${GREEN}✓ allow-from-prod.yaml saved${NC}"
else
    echo -e "${RED}✗ allow-from-prod.yaml not found at /opt/course/07/allow-from-prod.yaml${NC}"
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
