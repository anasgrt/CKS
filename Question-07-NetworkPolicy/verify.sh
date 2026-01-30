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

    # Get the policy in JSON format for detailed validation
    DENY_POLICY_JSON=$(kubectl get networkpolicy deny-all-ingress -n prod -o json 2>/dev/null)

    # Validate spec.podSelector is empty (applies to all pods)
    DENY_POD_SELECTOR=$(echo "$DENY_POLICY_JSON" | jq -r '.spec.podSelector // {}' 2>/dev/null)
    if [ "$DENY_POD_SELECTOR" == "{}" ]; then
        echo -e "${GREEN}✓ Policy applies to all pods (empty podSelector)${NC}"
    else
        echo -e "${RED}✗ spec.podSelector should be empty {} to apply to all pods${NC}"
        PASS=false
    fi

    # Validate policyTypes includes Ingress
    DENY_POLICY_TYPES=$(echo "$DENY_POLICY_JSON" | jq -r '.spec.policyTypes[]' 2>/dev/null)
    if [[ "$DENY_POLICY_TYPES" == *"Ingress"* ]]; then
        echo -e "${GREEN}✓ Policy includes Ingress type${NC}"
    else
        echo -e "${RED}✗ policyTypes must include 'Ingress'${NC}"
        PASS=false
    fi

    # Validate ingress is empty or not specified (deny all)
    DENY_INGRESS=$(echo "$DENY_POLICY_JSON" | jq '.spec.ingress' 2>/dev/null)
    DENY_INGRESS_LENGTH=$(echo "$DENY_POLICY_JSON" | jq '.spec.ingress | length' 2>/dev/null)

    if [ "$DENY_INGRESS" == "null" ] || [ "$DENY_INGRESS_LENGTH" == "0" ]; then
        echo -e "${GREEN}✓ No ingress rules (denies all ingress traffic)${NC}"
    else
        echo -e "${RED}✗ Ingress rules found - should be empty to deny all traffic${NC}"
        echo -e "${YELLOW}  Found: $DENY_INGRESS${NC}"
        PASS=false
    fi

    # Additional validation: ensure no egress rules (not required but good to check)
    HAS_EGRESS=$(echo "$DENY_POLICY_JSON" | jq 'has("egress")' 2>/dev/null)
    if [ "$HAS_EGRESS" == "false" ]; then
        echo -e "${GREEN}✓ No egress rules (correct for this task)${NC}"
    fi
else
    echo -e "${RED}✗ NetworkPolicy 'deny-all-ingress' not found in prod namespace${NC}"
    PASS=false
fi

echo ""
echo "Checking allow-from-prod in data namespace..."
if kubectl get networkpolicy allow-from-prod -n data &>/dev/null; then
    echo -e "${GREEN}✓ NetworkPolicy 'allow-from-prod' exists in data${NC}"

    # Get the policy in JSON format for detailed validation
    POLICY_JSON=$(kubectl get networkpolicy allow-from-prod -n data -o json 2>/dev/null)

    # Validate spec.podSelector is empty (applies to all pods)
    SPEC_POD_SELECTOR=$(echo "$POLICY_JSON" | jq -r '.spec.podSelector // {}' 2>/dev/null)
    if [ "$SPEC_POD_SELECTOR" == "{}" ]; then
        echo -e "${GREEN}✓ Policy applies to all pods (empty podSelector)${NC}"
    else
        echo -e "${RED}✗ spec.podSelector should be empty to apply to all pods in namespace${NC}"
        PASS=false
    fi

    # Validate policyTypes includes Ingress
    POLICY_TYPES=$(echo "$POLICY_JSON" | jq -r '.spec.policyTypes[]' 2>/dev/null)
    if [[ "$POLICY_TYPES" == *"Ingress"* ]]; then
        echo -e "${GREEN}✓ Policy includes Ingress type${NC}"
    else
        echo -e "${RED}✗ policyTypes should include 'Ingress'${NC}"
        PASS=false
    fi

    # Validate ingress rules exist
    INGRESS_LENGTH=$(echo "$POLICY_JSON" | jq '.spec.ingress | length' 2>/dev/null)
    if [ "$INGRESS_LENGTH" -gt 0 ]; then
        echo -e "${GREEN}✓ Has ingress rules defined${NC}"
    else
        echo -e "${RED}✗ No ingress rules found (would deny all)${NC}"
        PASS=false
    fi

    # Validate from block structure (critical for AND logic)
    FROM_LENGTH=$(echo "$POLICY_JSON" | jq '.spec.ingress[0].from | length' 2>/dev/null)
    if [ "$FROM_LENGTH" == "1" ]; then
        echo -e "${GREEN}✓ Has single 'from' element (AND condition)${NC}"

        # Check namespaceSelector exists in the from block
        NS_SELECTOR_EXISTS=$(echo "$POLICY_JSON" | jq '.spec.ingress[0].from[0] | has("namespaceSelector")' 2>/dev/null)
        if [ "$NS_SELECTOR_EXISTS" == "true" ]; then
            echo -e "${GREEN}✓ Has namespaceSelector in from block${NC}"

            # Validate namespace selector label (should be env: prod OR kubernetes.io/metadata.name: prod)
            NS_LABEL_KEY=$(echo "$POLICY_JSON" | jq -r '.spec.ingress[0].from[0].namespaceSelector.matchLabels | keys[0]' 2>/dev/null)
            NS_LABEL_VALUE=$(echo "$POLICY_JSON" | jq -r '.spec.ingress[0].from[0].namespaceSelector.matchLabels | .[]' 2>/dev/null)

            if [[ "$NS_LABEL_KEY" == "env" && "$NS_LABEL_VALUE" == "prod" ]] || \
               [[ "$NS_LABEL_KEY" == "kubernetes.io/metadata.name" && "$NS_LABEL_VALUE" == "prod" ]]; then
                echo -e "${GREEN}✓ namespaceSelector correctly targets prod namespace ($NS_LABEL_KEY: $NS_LABEL_VALUE)${NC}"
            else
                echo -e "${RED}✗ namespaceSelector should target prod namespace (found: $NS_LABEL_KEY: $NS_LABEL_VALUE)${NC}"
                PASS=false
            fi
        else
            echo -e "${RED}✗ Missing namespaceSelector in from block${NC}"
            PASS=false
        fi

        # Check podSelector exists in the same from block
        POD_SELECTOR_EXISTS=$(echo "$POLICY_JSON" | jq '.spec.ingress[0].from[0] | has("podSelector")' 2>/dev/null)
        if [ "$POD_SELECTOR_EXISTS" == "true" ]; then
            echo -e "${GREEN}✓ Has podSelector in from block (AND condition)${NC}"

            # Validate pod selector label (should be env: prod)
            POD_LABEL_KEY=$(echo "$POLICY_JSON" | jq -r '.spec.ingress[0].from[0].podSelector.matchLabels | keys[0]' 2>/dev/null)
            POD_LABEL_VALUE=$(echo "$POLICY_JSON" | jq -r '.spec.ingress[0].from[0].podSelector.matchLabels.env' 2>/dev/null)

            if [[ "$POD_LABEL_KEY" == "env" && "$POD_LABEL_VALUE" == "prod" ]]; then
                echo -e "${GREEN}✓ podSelector correctly targets env=prod pods${NC}"
            else
                echo -e "${RED}✗ podSelector should target pods with env=prod label${NC}"
                PASS=false
            fi
        else
            echo -e "${RED}✗ Missing podSelector in from block (should use AND condition)${NC}"
            PASS=false
        fi
    elif [ "$FROM_LENGTH" -gt 1 ]; then
        echo -e "${YELLOW}⚠ Multiple 'from' elements (OR condition) - task requires AND condition${NC}"
        echo -e "${YELLOW}  This would allow traffic from entire prod namespace OR any pod with env=prod${NC}"
        PASS=false
    else
        echo -e "${RED}✗ No 'from' rules defined${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ NetworkPolicy 'allow-from-prod' not found in data namespace${NC}"
    PASS=false
fi

# Check output files
echo ""
echo "Checking output files..."

# Verify deny-all-ingress.yaml
if [ -f "/opt/course/07/deny-all-ingress.yaml" ]; then
    # Check if it's valid YAML
    if kubectl apply --dry-run=client -f /opt/course/07/deny-all-ingress.yaml &>/dev/null; then
        # Check if it has the correct content
        FILE_KIND=$(grep -i "^kind:" /opt/course/07/deny-all-ingress.yaml | awk '{print $2}')
        FILE_NAME=$(grep -A 2 "^metadata:" /opt/course/07/deny-all-ingress.yaml | grep "name:" | awk '{print $2}')
        FILE_NS=$(grep -A 2 "^metadata:" /opt/course/07/deny-all-ingress.yaml | grep "namespace:" | awk '{print $2}')

        if [ "$FILE_KIND" == "NetworkPolicy" ] && [ "$FILE_NAME" == "deny-all-ingress" ] && [ "$FILE_NS" == "prod" ]; then
            echo -e "${GREEN}✓ deny-all-ingress.yaml is valid and correct${NC}"
        else
            echo -e "${RED}✗ deny-all-ingress.yaml has incorrect content (Kind=$FILE_KIND, Name=$FILE_NAME, NS=$FILE_NS)${NC}"
            PASS=false
        fi
    else
        echo -e "${RED}✗ deny-all-ingress.yaml is not valid YAML or not a valid NetworkPolicy${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ deny-all-ingress.yaml not found at /opt/course/07/deny-all-ingress.yaml${NC}"
    PASS=false
fi

# Verify allow-from-prod.yaml
if [ -f "/opt/course/07/allow-from-prod.yaml" ]; then
    # Check if it's valid YAML
    if kubectl apply --dry-run=client -f /opt/course/07/allow-from-prod.yaml &>/dev/null; then
        # Check if it has the correct content
        FILE_KIND=$(grep -i "^kind:" /opt/course/07/allow-from-prod.yaml | awk '{print $2}')
        FILE_NAME=$(grep -A 2 "^metadata:" /opt/course/07/allow-from-prod.yaml | grep "name:" | awk '{print $2}')
        FILE_NS=$(grep -A 2 "^metadata:" /opt/course/07/allow-from-prod.yaml | grep "namespace:" | awk '{print $2}')

        if [ "$FILE_KIND" == "NetworkPolicy" ] && [ "$FILE_NAME" == "allow-from-prod" ] && [ "$FILE_NS" == "data" ]; then
            echo -e "${GREEN}✓ allow-from-prod.yaml is valid and correct${NC}"
        else
            echo -e "${RED}✗ allow-from-prod.yaml has incorrect content (Kind=$FILE_KIND, Name=$FILE_NAME, NS=$FILE_NS)${NC}"
            PASS=false
        fi
    else
        echo -e "${RED}✗ allow-from-prod.yaml is not valid YAML or not a valid NetworkPolicy${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ allow-from-prod.yaml not found at /opt/course/07/allow-from-prod.yaml${NC}"
    PASS=false
fi

# Test actual connectivity
echo ""
echo "Testing Network Policy enforcement..."

# Wait for pods to be ready
if ! kubectl wait --for=condition=ready pod/prod-app -n prod --timeout=5s &>/dev/null || \
   ! kubectl wait --for=condition=ready pod/prod-worker -n prod --timeout=5s &>/dev/null || \
   ! kubectl wait --for=condition=ready pod/database -n data --timeout=5s &>/dev/null; then
    echo -e "${YELLOW}⚠ Some pods are not ready, skipping connectivity tests${NC}"
else
    # Test 1: prod-app (env=prod) should be able to reach database
    echo "Testing: prod-app (env=prod) → database-svc.data"
    if kubectl exec -n prod prod-app -- wget -qO- --timeout=2 database-svc.data &>/dev/null; then
        echo -e "${GREEN}✓ prod-app can reach database (EXPECTED - has env=prod label)${NC}"
    else
        echo -e "${RED}✗ prod-app cannot reach database (UNEXPECTED - should be allowed)${NC}"
        PASS=false
    fi

    # Test 2: prod-worker (env=worker) should NOT be able to reach database
    echo "Testing: prod-worker (env=worker) → database-svc.data"
    if kubectl exec -n prod prod-worker -- wget -qO- --timeout=2 database-svc.data &>/dev/null; then
        echo -e "${RED}✗ prod-worker can reach database (UNEXPECTED - should be blocked)${NC}"
        PASS=false
    else
        echo -e "${GREEN}✓ prod-worker blocked from database (EXPECTED - no env=prod label)${NC}"
    fi

    # Test 3: Verify deny-all-ingress in prod namespace
    # Check if we can reach prod-app from data namespace
    echo "Testing: database → prod-app.prod (verify deny-all-ingress)"
    if kubectl exec -n data database -- wget -qO- --timeout=2 prod-app.prod &>/dev/null; then
        echo -e "${RED}✗ database can reach prod-app (deny-all-ingress may not be working)${NC}"
        PASS=false
    else
        echo -e "${GREEN}✓ database blocked from prod-app (deny-all-ingress working)${NC}"
    fi
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
