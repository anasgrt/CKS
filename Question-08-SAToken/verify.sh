#!/bin/bash
# Verify Question 08 - ServiceAccount Token Mounting with Projected Volume

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking ServiceAccount Token Mounting..."
echo ""

# ============================================================================
# VERIFY SERVICEACCOUNT
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "PART 1: Checking ServiceAccount configuration"
echo "═══════════════════════════════════════════════════════════════"
echo ""

AUTOMOUNT=$(kubectl get sa stats-monitor-sa -n monitoring -o jsonpath='{.automountServiceAccountToken}' 2>/dev/null || echo "true")
if [ "$AUTOMOUNT" == "false" ]; then
    echo -e "${GREEN}✓ ServiceAccount has automountServiceAccountToken: false${NC}"
else
    echo -e "${RED}✗ ServiceAccount should have automountServiceAccountToken: false (current: $AUTOMOUNT)${NC}"
    PASS=false
fi

# ============================================================================
# VERIFY DEPLOYMENT
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "PART 2: Checking Deployment configuration"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Check for projected volume named 'token'
VOLUME_NAME=$(kubectl get deployment stats-monitor -n monitoring -o jsonpath='{.spec.template.spec.volumes[?(@.projected)].name}' 2>/dev/null || echo "")
if [ "$VOLUME_NAME" == "token" ]; then
    echo -e "${GREEN}✓ Deployment has projected volume named 'token'${NC}"
else
    echo -e "${RED}✗ Deployment should have a projected volume named 'token' (found: $VOLUME_NAME)${NC}"
    PASS=false
fi

# Check for serviceAccountToken in projected volume
SA_TOKEN_CHECK=$(kubectl get deployment stats-monitor -n monitoring -o jsonpath='{.spec.template.spec.volumes[?(@.name=="token")].projected.sources[*].serviceAccountToken}' 2>/dev/null || echo "")
if [ -n "$SA_TOKEN_CHECK" ]; then
    echo -e "${GREEN}✓ Projected volume has serviceAccountToken source${NC}"
else
    echo -e "${RED}✗ Projected volume should have serviceAccountToken source${NC}"
    PASS=false
fi

# Check expirationSeconds is set
EXPIRATION=$(kubectl get deployment stats-monitor -n monitoring -o json 2>/dev/null | jq -r '.spec.template.spec.volumes[] | select(.name=="token") | .projected.sources[].serviceAccountToken.expirationSeconds // ""' 2>/dev/null | head -1)
if [ "$EXPIRATION" == "3600" ]; then
    echo -e "${GREEN}✓ ServiceAccountToken has expirationSeconds: 3600${NC}"
elif [ -n "$EXPIRATION" ]; then
    echo -e "${YELLOW}⚠ ServiceAccountToken expirationSeconds is $EXPIRATION (expected: 3600)${NC}"
else
    echo -e "${RED}✗ ServiceAccountToken should have expirationSeconds: 3600${NC}"
    PASS=false
fi

# Check audience is set
AUDIENCE=$(kubectl get deployment stats-monitor -n monitoring -o json 2>/dev/null | jq -r '.spec.template.spec.volumes[] | select(.name=="token") | .projected.sources[].serviceAccountToken.audience // ""' 2>/dev/null | head -1)
if [ -n "$AUDIENCE" ]; then
    echo -e "${GREEN}✓ ServiceAccountToken has audience configured: $AUDIENCE${NC}"
else
    echo -e "${RED}✗ ServiceAccountToken should have audience configured (e.g., https://kubernetes.default.svc.cluster.local)${NC}"
    PASS=false
fi

# Check volume mount exists
MOUNT_PATH=$(kubectl get deployment stats-monitor -n monitoring -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[?(@.name=="token")].mountPath}' 2>/dev/null || echo "")
if [ -n "$MOUNT_PATH" ]; then
    echo -e "${GREEN}✓ Deployment has volume mount for 'token' at: $MOUNT_PATH${NC}"
else
    echo -e "${RED}✗ Deployment should have volume mount for 'token'${NC}"
    PASS=false
fi

# Check mount is read-only
READ_ONLY=$(kubectl get deployment stats-monitor -n monitoring -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[?(@.name=="token")].readOnly}' 2>/dev/null || echo "")
if [ "$READ_ONLY" == "true" ]; then
    echo -e "${GREEN}✓ Volume mount is read-only${NC}"
else
    echo -e "${RED}✗ Volume mount should be read-only (current: $READ_ONLY)${NC}"
    PASS=false
fi

# ============================================================================
# VERIFY RUNTIME
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "PART 3: Checking runtime token availability"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Wait for pod to be ready
POD_NAME=$(kubectl get pods -n monitoring -l app=stats-monitor -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$POD_NAME" ]; then
    echo -e "${GREEN}✓ Pod is running: $POD_NAME${NC}"

    # Check if token file exists
    if kubectl exec -n monitoring "$POD_NAME" -- test -f /var/run/secrets/kubernetes.io/serviceaccount/token 2>/dev/null; then
        echo -e "${GREEN}✓ ServiceAccount token is mounted in pod${NC}"

        # Verify token is not empty
        TOKEN_SIZE=$(kubectl exec -n monitoring "$POD_NAME" -- wc -c /var/run/secrets/kubernetes.io/serviceaccount/token 2>/dev/null | awk '{print $1}')
        if [ -n "$TOKEN_SIZE" ] && [ "$TOKEN_SIZE" -gt 0 ]; then
            echo -e "${GREEN}✓ Token file is not empty (${TOKEN_SIZE} bytes)${NC}"
        else
            echo -e "${RED}✗ Token file is empty${NC}"
            PASS=false
        fi
    else
        echo -e "${RED}✗ ServiceAccount token not found in pod${NC}"
        PASS=false
    fi
else
    echo -e "${YELLOW}⚠ No pod found for deployment${NC}"
fi

# ============================================================================
# VERIFY MANIFEST FILE
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "PART 4: Checking manifest file"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ -f "$HOME/stats-monitor/deployment.yaml" ]; then
    echo -e "${GREEN}✓ Deployment manifest exists at ~/stats-monitor/deployment.yaml${NC}"

    # Validate manifest file content
    if kubectl apply --dry-run=client -f "$HOME/stats-monitor/deployment.yaml" &>/dev/null; then
        FILE_JSON=$(kubectl apply --dry-run=client -f "$HOME/stats-monitor/deployment.yaml" -o json 2>/dev/null)

        # Check if it has projected volume
        HAS_PROJECTED=$(echo "$FILE_JSON" | jq '.spec.template.spec.volumes[] | select(.projected != null)' 2>/dev/null)
        if [ -n "$HAS_PROJECTED" ]; then
            echo -e "${GREEN}✓ Manifest file has projected volume configured${NC}"

            # Check for serviceAccountToken in projected volume
            HAS_SA_TOKEN=$(echo "$FILE_JSON" | jq '.spec.template.spec.volumes[].projected.sources[]? | select(.serviceAccountToken != null)' 2>/dev/null)
            if [ -n "$HAS_SA_TOKEN" ]; then
                echo -e "${GREEN}✓ Manifest file has serviceAccountToken in projected volume${NC}"
            else
                echo -e "${YELLOW}⚠ Manifest file missing serviceAccountToken in projected volume${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ Manifest file missing projected volume configuration${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Manifest file has invalid YAML syntax${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Deployment manifest file not found at ~/stats-monitor/deployment.yaml${NC}"
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "Summary"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if $PASS; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Configuration verified:"
    echo "  ServiceAccount:"
    echo "    ✓ automountServiceAccountToken: false"
    echo "  Deployment:"
    echo "    ✓ Projected volume 'token' with serviceAccountToken"
    echo "    ✓ expirationSeconds: 3600"
    echo "    ✓ audience configured for API server"
    echo "    ✓ Volume mount is read-only"
    echo "    ✓ Token injected at correct path"
    exit 0
else
    echo -e "${RED}✗ Some checks failed${NC}"
    echo ""
    echo "Expected configuration:"
    echo "  ServiceAccount:"
    echo "    - automountServiceAccountToken: false"
    echo "  Deployment:"
    echo "    - Projected volume named 'token'"
    echo "    - serviceAccountToken with:"
    echo "      * expirationSeconds: 3600"
    echo "      * audience: https://kubernetes.default.svc.cluster.local (or cluster-specific)"
    echo "      * path: token (filename inside mounted directory)"
    echo "    - Volume mount at /var/run/secrets/kubernetes.io/serviceaccount (directory)"
    echo "    - Token accessible at: /var/run/secrets/kubernetes.io/serviceaccount/token"
    echo "    - Mount must be read-only: true"
    echo ""
    echo "To discover audience:"
    echo "  kubectl get --raw /.well-known/openid-configuration | jq -r '.issuer'"
    exit 1
fi
