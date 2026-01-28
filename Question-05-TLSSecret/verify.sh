#!/bin/bash
# Verify Question 05 - Create TLS Secret

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking TLS Secret creation..."
echo ""

# Check namespace exists
if kubectl get namespace secure-ns &>/dev/null; then
    echo -e "${GREEN}✓ Namespace 'secure-ns' exists${NC}"
else
    echo -e "${RED}✗ Namespace 'secure-ns' not found${NC}"
    PASS=false
fi

# Check secret exists
if kubectl get secret my-tls-secret -n secure-ns &>/dev/null; then
    echo -e "${GREEN}✓ Secret 'my-tls-secret' exists${NC}"
else
    echo -e "${RED}✗ Secret 'my-tls-secret' not found in namespace 'secure-ns'${NC}"
    PASS=false
fi

# Check secret type
SECRET_TYPE=$(kubectl get secret my-tls-secret -n secure-ns -o jsonpath='{.type}' 2>/dev/null || echo "")
if [ "$SECRET_TYPE" == "kubernetes.io/tls" ]; then
    echo -e "${GREEN}✓ Secret type is 'kubernetes.io/tls'${NC}"
else
    echo -e "${RED}✗ Secret type should be 'kubernetes.io/tls' (found: '$SECRET_TYPE')${NC}"
    PASS=false
fi

# Check secret has tls.crt and tls.key
TLS_CRT=$(kubectl get secret my-tls-secret -n secure-ns -o jsonpath='{.data.tls\.crt}' 2>/dev/null || echo "")
TLS_KEY=$(kubectl get secret my-tls-secret -n secure-ns -o jsonpath='{.data.tls\.key}' 2>/dev/null || echo "")

if [ -n "$TLS_CRT" ]; then
    echo -e "${GREEN}✓ Secret contains tls.crt${NC}"
else
    echo -e "${RED}✗ Secret missing tls.crt${NC}"
    PASS=false
fi

if [ -n "$TLS_KEY" ]; then
    echo -e "${GREEN}✓ Secret contains tls.key${NC}"
else
    echo -e "${RED}✗ Secret missing tls.key${NC}"
    PASS=false
fi

# Check command file
echo ""
echo "Checking output files..."
if [ -f "/opt/course/05/create-secret.txt" ]; then
    echo -e "${GREEN}✓ create-secret.txt saved${NC}"
else
    echo -e "${RED}✗ create-secret.txt not found at /opt/course/05/create-secret.txt${NC}"
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
