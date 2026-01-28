#!/bin/bash
# Verify Question 12 - Dockerfile and Deployment Security

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Dockerfile and Deployment Security..."
echo ""

# Check Dockerfile-fixed
echo "Checking fixed Dockerfile..."
if [ -f "/opt/course/12/Dockerfile-fixed" ]; then
    echo -e "${GREEN}✓ Dockerfile-fixed exists${NC}"

    # Check for specific version (not :latest)
    if grep -q "nginx:latest" /opt/course/12/Dockerfile-fixed; then
        echo -e "${RED}✗ Should not use :latest tag${NC}"
        PASS=false
    else
        echo -e "${GREEN}✓ Not using :latest tag${NC}"
    fi

    # Check for USER instruction
    if grep -qi "^USER" /opt/course/12/Dockerfile-fixed; then
        echo -e "${GREEN}✓ Has USER instruction${NC}"
    else
        echo -e "${RED}✗ Should have USER instruction for non-root${NC}"
        PASS=false
    fi

    # Check ADD is replaced with COPY for local files
    ADD_COUNT=$(grep -c "^ADD" /opt/course/12/Dockerfile-fixed 2>/dev/null || echo "0")
    if [ "$ADD_COUNT" -le 1 ]; then  # Allow one ADD for .tar.gz
        echo -e "${GREEN}✓ Using COPY instead of ADD for local files${NC}"
    else
        echo -e "${YELLOW}⚠ Consider using COPY instead of ADD for local files${NC}"
    fi
else
    echo -e "${RED}✗ Dockerfile-fixed not found at /opt/course/12/Dockerfile-fixed${NC}"
    PASS=false
fi

# Check deployment-fixed.yaml
echo ""
echo "Checking fixed Deployment..."
if [ -f "/opt/course/12/deployment-fixed.yaml" ]; then
    echo -e "${GREEN}✓ deployment-fixed.yaml exists${NC}"

    # Check privileged: false
    if grep -q "privileged: false" /opt/course/12/deployment-fixed.yaml; then
        echo -e "${GREEN}✓ Has privileged: false${NC}"
    else
        echo -e "${RED}✗ Should have privileged: false${NC}"
        PASS=false
    fi

    # Check allowPrivilegeEscalation: false
    if grep -q "allowPrivilegeEscalation: false" /opt/course/12/deployment-fixed.yaml; then
        echo -e "${GREEN}✓ Has allowPrivilegeEscalation: false${NC}"
    else
        echo -e "${RED}✗ Should have allowPrivilegeEscalation: false${NC}"
        PASS=false
    fi

    # Check runAsNonRoot: true
    if grep -q "runAsNonRoot: true" /opt/course/12/deployment-fixed.yaml; then
        echo -e "${GREEN}✓ Has runAsNonRoot: true${NC}"
    else
        echo -e "${RED}✗ Should have runAsNonRoot: true${NC}"
        PASS=false
    fi

    # Check readOnlyRootFilesystem: true
    if grep -q "readOnlyRootFilesystem: true" /opt/course/12/deployment-fixed.yaml; then
        echo -e "${GREEN}✓ Has readOnlyRootFilesystem: true${NC}"
    else
        echo -e "${YELLOW}⚠ Consider adding readOnlyRootFilesystem: true${NC}"
    fi
else
    echo -e "${RED}✗ deployment-fixed.yaml not found at /opt/course/12/deployment-fixed.yaml${NC}"
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
