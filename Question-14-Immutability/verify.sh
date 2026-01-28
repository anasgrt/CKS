#!/bin/bash
# Verify Question 14 - Ensure Immutability of Containers at Runtime

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Container Immutability..."
echo ""

# Check deployment exists
if kubectl get deployment nginx -n immutable-ns &>/dev/null; then
    echo -e "${GREEN}✓ Deployment 'nginx' exists${NC}"
else
    echo -e "${RED}✗ Deployment 'nginx' not found in immutable-ns${NC}"
    PASS=false
fi

# Check readOnlyRootFilesystem
echo ""
echo "Checking securityContext..."
READ_ONLY=$(kubectl get deployment nginx -n immutable-ns -o jsonpath='{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}' 2>/dev/null || echo "")
if [ "$READ_ONLY" == "true" ]; then
    echo -e "${GREEN}✓ readOnlyRootFilesystem is true${NC}"
else
    echo -e "${RED}✗ readOnlyRootFilesystem should be true${NC}"
    PASS=false
fi

# Check for emptyDir volumes
echo ""
echo "Checking volumes..."
VOLUMES=$(kubectl get deployment nginx -n immutable-ns -o jsonpath='{.spec.template.spec.volumes[*].name}' 2>/dev/null || echo "")
if [ -n "$VOLUMES" ]; then
    echo -e "${GREEN}✓ Deployment has volumes configured${NC}"

    # Check for emptyDir type
    EMPTY_DIR=$(kubectl get deployment nginx -n immutable-ns -o json 2>/dev/null | grep -c "emptyDir" || echo "0")
    if [ "$EMPTY_DIR" -ge 1 ]; then
        echo -e "${GREEN}✓ Has emptyDir volume(s)${NC}"
    else
        echo -e "${RED}✗ Should have emptyDir volumes for writable paths${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ No volumes configured (need emptyDir for writable paths)${NC}"
    PASS=false
fi

# Check volume mounts
MOUNTS=$(kubectl get deployment nginx -n immutable-ns -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[*].mountPath}' 2>/dev/null || echo "")
if [[ "$MOUNTS" == *"/var/cache/nginx"* ]] || [[ "$MOUNTS" == *"/var/run"* ]]; then
    echo -e "${GREEN}✓ Has required volume mounts${NC}"
else
    echo -e "${YELLOW}⚠ Should have mounts for /var/cache/nginx and /var/run${NC}"
fi

# Check pod is running
echo ""
echo "Checking pod status..."
POD_STATUS=$(kubectl get pods -n immutable-ns -l app=nginx -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "")
if [ "$POD_STATUS" == "Running" ]; then
    echo -e "${GREEN}✓ Pod is running${NC}"
else
    echo -e "${RED}✗ Pod is not running (status: $POD_STATUS)${NC}"
    PASS=false
fi

# Check output file
echo ""
echo "Checking output files..."
if [ -f "/opt/course/14/deployment-immutable.yaml" ]; then
    echo -e "${GREEN}✓ deployment-immutable.yaml saved${NC}"
else
    echo -e "${RED}✗ deployment-immutable.yaml not found at /opt/course/14/deployment-immutable.yaml${NC}"
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
