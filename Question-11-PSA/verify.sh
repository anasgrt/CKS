#!/bin/bash
# Verify Question 11 - Pod Security Admission

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Pod Security Admission task..."
echo ""

# Check namespace has the PSA label applied
echo "Checking namespace labels..."
PSA_LABEL=$(kubectl get ns team-blue -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)
if [ "$PSA_LABEL" == "restricted" ]; then
    echo -e "${GREEN}✓ Namespace team-blue has pod-security.kubernetes.io/enforce=restricted label${NC}"
else
    echo -e "${RED}✗ Namespace team-blue is missing the enforce=restricted label${NC}"
    echo -e "${YELLOW}  Run: kubectl label --overwrite ns team-blue pod-security.kubernetes.io/enforce=restricted${NC}"
    PASS=false
fi

echo ""
echo "Checking pod status..."

# Check non-compliant pods are deleted
# Check hostnetwork-pod is deleted
if kubectl get pod hostnetwork-pod -n team-blue &>/dev/null; then
    echo -e "${RED}✗ hostnetwork-pod should be deleted (violates restricted: hostNetwork)${NC}"
    PASS=false
else
    echo -e "${GREEN}✓ hostnetwork-pod has been deleted${NC}"
fi

# Check root-pod is deleted
if kubectl get pod root-pod -n team-blue &>/dev/null; then
    echo -e "${RED}✗ root-pod should be deleted (violates restricted: runAsNonRoot)${NC}"
    PASS=false
else
    echo -e "${GREEN}✓ root-pod has been deleted${NC}"
fi

# Check escalation-pod is deleted
if kubectl get pod escalation-pod -n team-blue &>/dev/null; then
    echo -e "${RED}✗ escalation-pod should be deleted (violates restricted: allowPrivilegeEscalation)${NC}"
    PASS=false
else
    echo -e "${GREEN}✓ escalation-pod has been deleted${NC}"
fi

# Check compliant-pod is still running
if kubectl get pod compliant-pod -n team-blue &>/dev/null; then
    STATUS=$(kubectl get pod compliant-pod -n team-blue -o jsonpath='{.status.phase}')
    if [ "$STATUS" == "Running" ]; then
        echo -e "${GREEN}✓ compliant-pod is still running${NC}"
    else
        echo -e "${YELLOW}⚠ compliant-pod exists but status is: $STATUS${NC}"
    fi
else
    echo -e "${RED}✗ compliant-pod should still be running!${NC}"
    PASS=false
fi

# Check output files
echo ""
echo "Checking output files..."

if [ -f "/opt/course/11/violations.txt" ]; then
    if grep -qi "warning" /opt/course/11/violations.txt 2>/dev/null; then
        echo -e "${GREEN}✓ violations.txt saved with warning output${NC}"
    else
        echo -e "${YELLOW}⚠ violations.txt exists but may not contain warnings${NC}"
    fi
else
    echo -e "${RED}✗ violations.txt not found at /opt/course/11/violations.txt${NC}"
    PASS=false
fi

if [ -f "/opt/course/11/deleted-pods.txt" ]; then
    # Verify content has pods listed (one per line)
    POD_COUNT=$(grep -c -E "hostnetwork-pod|root-pod|escalation-pod" /opt/course/11/deleted-pods.txt 2>/dev/null || echo "0")
    if [ "$POD_COUNT" -ge 3 ]; then
        echo -e "${GREEN}✓ deleted-pods.txt contains all deleted pod names${NC}"
    elif [ "$POD_COUNT" -ge 1 ]; then
        echo -e "${YELLOW}⚠ deleted-pods.txt exists but may be missing some pod names${NC}"
    else
        echo -e "${YELLOW}⚠ deleted-pods.txt exists - verify it contains pod names (one per line)${NC}"
    fi
else
    echo -e "${RED}✗ deleted-pods.txt not found at /opt/course/11/deleted-pods.txt${NC}"
    PASS=false
fi

if [ -f "/opt/course/11/command.txt" ]; then
    if grep -q "kubectl label" /opt/course/11/command.txt 2>/dev/null && \
       grep -q "pod-security.kubernetes.io/enforce=restricted" /opt/course/11/command.txt 2>/dev/null; then
        echo -e "${GREEN}✓ command.txt contains the correct kubectl label command${NC}"
    else
        echo -e "${YELLOW}⚠ command.txt exists but may not contain the correct command${NC}"
    fi
else
    echo -e "${RED}✗ command.txt not found at /opt/course/11/command.txt${NC}"
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
