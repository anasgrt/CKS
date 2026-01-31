#!/bin/bash
# Verify Question 14 - Ensure Immutability of Containers at Runtime

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Container Immutability and Security..."
echo ""

# ============================================================================
# TASK 1: Verify nginx immutability
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "TASK 1: Checking nginx Container Immutability"
echo "═══════════════════════════════════════════════════════════════"
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
echo "Checking nginx securityContext..."
READ_ONLY=$(kubectl get deployment nginx -n immutable-ns -o jsonpath='{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}' 2>/dev/null || echo "")
if [ "$READ_ONLY" == "true" ]; then
    echo -e "${GREEN}✓ nginx: readOnlyRootFilesystem is true${NC}"
else
    echo -e "${RED}✗ nginx: readOnlyRootFilesystem should be true${NC}"
    PASS=false
fi

# Check for emptyDir volumes
echo ""
echo "Checking nginx volumes..."
VOLUMES=$(kubectl get deployment nginx -n immutable-ns -o jsonpath='{.spec.template.spec.volumes[*].name}' 2>/dev/null || echo "")
if [ -n "$VOLUMES" ]; then
    echo -e "${GREEN}✓ nginx: Deployment has volumes configured${NC}"

    # Check for emptyDir type
    EMPTY_DIR=$(kubectl get deployment nginx -n immutable-ns -o json 2>/dev/null | grep -c "emptyDir" || echo "0")
    if [ "$EMPTY_DIR" -ge 1 ]; then
        echo -e "${GREEN}✓ nginx: Has emptyDir volume(s)${NC}"
    else
        echo -e "${RED}✗ nginx: Should have emptyDir volumes for writable paths${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ nginx: No volumes configured (need emptyDir for writable paths)${NC}"
    PASS=false
fi

# Check volume mounts
MOUNTS=$(kubectl get deployment nginx -n immutable-ns -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[*].mountPath}' 2>/dev/null || echo "")
if [[ "$MOUNTS" == *"/var/cache/nginx"* ]] || [[ "$MOUNTS" == *"/var/run"* ]]; then
    echo -e "${GREEN}✓ nginx: Has required volume mounts${NC}"
else
    echo -e "${YELLOW}⚠ nginx: Should have mounts for /var/cache/nginx and /var/run${NC}"
fi

# Check pod is running
echo ""
echo "Checking nginx pod status..."
POD_STATUS=$(kubectl get pods -n immutable-ns -l app=nginx -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "")
if [ "$POD_STATUS" == "Running" ]; then
    echo -e "${GREEN}✓ nginx: Pod is running${NC}"
else
    echo -e "${RED}✗ nginx: Pod is not running (status: $POD_STATUS)${NC}"
    PASS=false
fi

# Check output file
echo ""
echo "Checking nginx output file..."
if [ -f "/opt/course/14/deployment-immutable.yaml" ]; then
    echo -e "${GREEN}✓ deployment-immutable.yaml saved${NC}"
else
    echo -e "${RED}✗ deployment-immutable.yaml not found at /opt/course/14/deployment-immutable.yaml${NC}"
    PASS=false
fi

# ============================================================================
# TASK 2: Verify lamp-deployment security
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "TASK 2: Checking lamp-deployment Security Context"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Check deployment exists
if kubectl get deployment lamp-deployment -n lamp &>/dev/null; then
    echo -e "${GREEN}✓ Deployment 'lamp-deployment' exists${NC}"
else
    echo -e "${RED}✗ Deployment 'lamp-deployment' not found in lamp namespace${NC}"
    PASS=false
fi

# Check runAsUser
echo ""
echo "Checking lamp-deployment securityContext..."
RUN_AS_USER=$(kubectl get deployment lamp-deployment -n lamp -o jsonpath='{.spec.template.spec.containers[0].securityContext.runAsUser}' 2>/dev/null || echo "")
if [ "$RUN_AS_USER" == "20000" ]; then
    echo -e "${GREEN}✓ lamp: runAsUser is 20000${NC}"
else
    echo -e "${RED}✗ lamp: runAsUser should be 20000 (current: $RUN_AS_USER)${NC}"
    PASS=false
fi

# Check readOnlyRootFilesystem
LAMP_READ_ONLY=$(kubectl get deployment lamp-deployment -n lamp -o jsonpath='{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}' 2>/dev/null || echo "")
if [ "$LAMP_READ_ONLY" == "true" ]; then
    echo -e "${GREEN}✓ lamp: readOnlyRootFilesystem is true${NC}"
else
    echo -e "${RED}✗ lamp: readOnlyRootFilesystem should be true${NC}"
    PASS=false
fi

# Check allowPrivilegeEscalation
PRIV_ESC=$(kubectl get deployment lamp-deployment -n lamp -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}' 2>/dev/null || echo "")
if [ "$PRIV_ESC" == "false" ]; then
    echo -e "${GREEN}✓ lamp: allowPrivilegeEscalation is false${NC}"
else
    echo -e "${RED}✗ lamp: allowPrivilegeEscalation should be false${NC}"
    PASS=false
fi

# Check for emptyDir volumes (lamp may need them too)
echo ""
echo "Checking lamp-deployment volumes..."
LAMP_VOLUMES=$(kubectl get deployment lamp-deployment -n lamp -o jsonpath='{.spec.template.spec.volumes[*].name}' 2>/dev/null || echo "")
if [ -n "$LAMP_VOLUMES" ]; then
    echo -e "${GREEN}✓ lamp: Deployment has volumes configured${NC}"

    LAMP_EMPTY_DIR=$(kubectl get deployment lamp-deployment -n lamp -o json 2>/dev/null | grep -c "emptyDir" || echo "0")
    if [ "$LAMP_EMPTY_DIR" -ge 1 ]; then
        echo -e "${GREEN}✓ lamp: Has emptyDir volume(s)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ lamp: May need emptyDir volumes for Apache writable paths${NC}"
fi

# Check lamp pod is running
echo ""
echo "Checking lamp-deployment pod status..."
LAMP_POD_STATUS=$(kubectl get pods -n lamp -l app=lamp -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "")
if [ "$LAMP_POD_STATUS" == "Running" ]; then
    echo -e "${GREEN}✓ lamp: Pod is running${NC}"
else
    echo -e "${RED}✗ lamp: Pod is not running (status: $LAMP_POD_STATUS)${NC}"
    PASS=false
fi

# Check lamp output file
echo ""
echo "Checking lamp-deployment output file..."
if [ -f "/opt/course/14/lamp-deployment.yaml" ]; then
    echo -e "${GREEN}✓ lamp-deployment.yaml saved${NC}"
else
    echo -e "${RED}✗ lamp-deployment.yaml not found at /opt/course/14/lamp-deployment.yaml${NC}"
    PASS=false
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
    echo "Task 1 - nginx:"
    echo "  ✓ readOnlyRootFilesystem: true"
    echo "  ✓ emptyDir volumes configured"
    echo "  ✓ Pod running successfully"
    echo ""
    echo "Task 2 - lamp-deployment:"
    echo "  ✓ runAsUser: 20000"
    echo "  ✓ readOnlyRootFilesystem: true"
    echo "  ✓ allowPrivilegeEscalation: false"
    echo "  ✓ Pod running successfully"
    exit 0
else
    echo -e "${RED}✗ Some checks failed${NC}"
    echo ""
    echo "Expected configuration:"
    echo ""
    echo "Task 1 - nginx (immutable-ns):"
    echo "  - readOnlyRootFilesystem: true"
    echo "  - emptyDir volumes for /var/cache/nginx, /var/run"
    echo "  - File: /opt/course/14/deployment-immutable.yaml"
    echo ""
    echo "Task 2 - lamp-deployment (lamp):"
    echo "  - runAsUser: 20000"
    echo "  - readOnlyRootFilesystem: true"
    echo "  - allowPrivilegeEscalation: false"
    echo "  - emptyDir volumes for Apache paths (if needed)"
    echo "  - File: /opt/course/14/lamp-deployment.yaml"
    exit 1
fi
