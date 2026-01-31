#!/bin/bash
# Verify Question 12 - Dockerfile and Deployment Security

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Dockerfile and Deployment Security fixes..."
echo ""

# ============================================================================
# VERIFY DOCKERFILE (2 changes expected)
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "PART 1: Checking Dockerfile fixes"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ -f "/opt/course/12/Dockerfile" ]; then
    echo -e "${GREEN}✓ Dockerfile exists at /opt/course/12/Dockerfile${NC}"
    echo ""

    # Check 1: FROM instruction should use ubuntu:16.04 (not :latest)
    FROM_LINE=$(grep "^FROM" /opt/course/12/Dockerfile)
    if echo "$FROM_LINE" | grep -q "ubuntu:16.04"; then
        echo -e "${GREEN}✓ FROM ubuntu:16.04 (using specific version)${NC}"
    elif echo "$FROM_LINE" | grep -q "ubuntu:latest"; then
        echo -e "${RED}✗ Still using ubuntu:latest (should be ubuntu:16.04)${NC}"
        PASS=false
    else
        echo -e "${YELLOW}⚠ FROM instruction: $FROM_LINE${NC}"
        echo -e "${YELLOW}  Expected: FROM ubuntu:16.04${NC}"
    fi

    # Check 2: USER instruction should use nobody (not root)
    USER_LINE=$(grep "^USER" /opt/course/12/Dockerfile)
    if echo "$USER_LINE" | grep -q "USER nobody"; then
        echo -e "${GREEN}✓ USER nobody (running as unprivileged user)${NC}"
    elif echo "$USER_LINE" | grep -q "USER root"; then
        echo -e "${RED}✗ Still using USER root (should be USER nobody)${NC}"
        PASS=false
    else
        echo -e "${YELLOW}⚠ USER instruction: $USER_LINE${NC}"
        echo -e "${YELLOW}  Expected: USER nobody${NC}"
    fi

    echo ""
    echo "Current Dockerfile:"
    echo "-------------------"
    cat /opt/course/12/Dockerfile | grep -E "^FROM|^USER"
    echo ""
else
    echo -e "${RED}✗ Dockerfile not found at /opt/course/12/Dockerfile${NC}"
    PASS=false
fi

# ============================================================================
# VERIFY DEPLOYMENT (2 changes expected)
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "PART 2: Checking Deployment fixes"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ -f "/opt/course/12/deployment.yaml" ]; then
    echo -e "${GREEN}✓ deployment.yaml exists at /opt/course/12/deployment.yaml${NC}"
    echo ""

    # Check 1: privileged should be false
    if grep -q "privileged: false" /opt/course/12/deployment.yaml; then
        echo -e "${GREEN}✓ privileged: false (not running in privileged mode)${NC}"
    elif grep -q "privileged: true" /opt/course/12/deployment.yaml; then
        echo -e "${RED}✗ Still has privileged: true (should be false)${NC}"
        PASS=false
    else
        echo -e "${YELLOW}⚠ Could not find 'privileged' field${NC}"
    fi

    # Check 2: readOnlyRootFilesystem should be true
    if grep -q "readOnlyRootFilesystem: true" /opt/course/12/deployment.yaml; then
        echo -e "${GREEN}✓ readOnlyRootFilesystem: true (immutable filesystem)${NC}"
    elif grep -q "readOnlyRootFilesystem: false" /opt/course/12/deployment.yaml; then
        echo -e "${RED}✗ Still has readOnlyRootFilesystem: false (should be true)${NC}"
        PASS=false
    else
        echo -e "${YELLOW}⚠ Could not find 'readOnlyRootFilesystem' field${NC}"
    fi

    echo ""
    echo "Current securityContext:"
    echo "------------------------"
    grep -A8 "securityContext:" /opt/course/12/deployment.yaml | head -10
    echo ""
else
    echo -e "${RED}✗ deployment.yaml not found at /opt/course/12/deployment.yaml${NC}"
    PASS=false
fi

# ============================================================================
# VERIFY DEPLOYMENT CAN BE APPLIED
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "PART 3: Testing deployment application"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if kubectl apply -f /opt/course/12/deployment.yaml --dry-run=client &>/dev/null; then
    echo -e "${GREEN}✓ Deployment manifest is valid (dry-run successful)${NC}"
else
    echo -e "${YELLOW}⚠ Deployment manifest may have syntax issues${NC}"
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
    echo "Changes verified:"
    echo "  Dockerfile:"
    echo "    ✓ FROM ubuntu:16.04"
    echo "    ✓ USER nobody"
    echo "  Deployment:"
    echo "    ✓ privileged: false"
    echo "    ✓ readOnlyRootFilesystem: true"
    exit 0
else
    echo -e "${RED}✗ Some checks failed${NC}"
    echo ""
    echo "Expected changes:"
    echo "  Dockerfile:"
    echo "    - FROM ubuntu:latest → FROM ubuntu:16.04"
    echo "    - USER root → USER nobody"
    echo "  Deployment:"
    echo "    - privileged: true → privileged: false"
    echo "    - readOnlyRootFilesystem: false → readOnlyRootFilesystem: true"
    exit 1
fi
