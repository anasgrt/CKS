#!/bin/bash
# Verify Question 08 - ServiceAccount Token Mounting with Projected Volume

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking ServiceAccount Token Mounting..."
echo ""

# Check ServiceAccount automountServiceAccountToken
echo "Checking ServiceAccount configuration..."
AUTOMOUNT=$(kubectl get sa backend-sa -n secure -o jsonpath='{.automountServiceAccountToken}' 2>/dev/null || echo "true")
if [ "$AUTOMOUNT" == "false" ]; then
    echo -e "${GREEN}✓ ServiceAccount has automountServiceAccountToken: false${NC}"
else
    echo -e "${RED}✗ ServiceAccount should have automountServiceAccountToken: false${NC}"
    PASS=false
fi

# Check Deployment has projected volume
echo ""
echo "Checking Deployment configuration..."

# Check for projected volume named 'token'
VOLUME_NAME=$(kubectl get deployment backend-deploy -n secure -o jsonpath='{.spec.template.spec.volumes[?(@.projected)].name}' 2>/dev/null || echo "")
if [ -n "$VOLUME_NAME" ]; then
    echo -e "${GREEN}✓ Deployment has projected volume${NC}"
else
    echo -e "${RED}✗ Deployment should have a projected volume${NC}"
    PASS=false
fi

# Check for serviceAccountToken in projected volume
SA_TOKEN=$(kubectl get deployment backend-deploy -n secure -o json 2>/dev/null | grep -c "serviceAccountToken" || echo "0")
if [ "$SA_TOKEN" -ge 1 ]; then
    echo -e "${GREEN}✓ Projected volume has serviceAccountToken source${NC}"
else
    echo -e "${RED}✗ Projected volume should have serviceAccountToken source${NC}"
    PASS=false
fi

# Check volume mount exists
VOLUME_MOUNT=$(kubectl get deployment backend-deploy -n secure -o json 2>/dev/null | grep -c "volumeMounts" || echo "0")
if [ "$VOLUME_MOUNT" -ge 1 ]; then
    echo -e "${GREEN}✓ Deployment has volume mounts${NC}"
else
    echo -e "${RED}✗ Deployment should have volume mounts${NC}"
    PASS=false
fi

# Check mount is read-only
READ_ONLY=$(kubectl get deployment backend-deploy -n secure -o json 2>/dev/null | grep -c '"readOnly": true' || echo "0")
if [ "$READ_ONLY" -ge 1 ]; then
    echo -e "${GREEN}✓ Volume mount is read-only${NC}"
else
    echo -e "${YELLOW}⚠ Volume mount should be read-only${NC}"
fi

# Check output files
echo ""
echo "Checking output files..."

if [ -f "/opt/course/08/serviceaccount.yaml" ]; then
    echo -e "${GREEN}✓ serviceaccount.yaml saved${NC}"
else
    echo -e "${RED}✗ serviceaccount.yaml not found at /opt/course/08/serviceaccount.yaml${NC}"
    PASS=false
fi

if [ -f "/opt/course/08/deployment.yaml" ]; then
    echo -e "${GREEN}✓ deployment.yaml saved${NC}"
else
    echo -e "${RED}✗ deployment.yaml not found at /opt/course/08/deployment.yaml${NC}"
    PASS=false
fi

# Check pod is running
echo ""
echo "Checking pod status..."
POD_STATUS=$(kubectl get pods -n secure -l app=backend -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "")
if [ "$POD_STATUS" == "Running" ]; then
    echo -e "${GREEN}✓ Backend pod is running${NC}"
else
    echo -e "${RED}✗ Backend pod is not running (status: $POD_STATUS)${NC}"
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
