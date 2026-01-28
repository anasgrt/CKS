#!/bin/bash
# Verify Question 03 - Ingress with TLS and HTTP to HTTPS Redirect

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Ingress with TLS configuration..."
echo ""

# Check ingress exists
if kubectl get ingress secure-ingress -n secure-app &>/dev/null; then
    echo -e "${GREEN}✓ Ingress 'secure-ingress' exists${NC}"
else
    echo -e "${RED}✗ Ingress 'secure-ingress' not found in namespace 'secure-app'${NC}"
    PASS=false
fi

# Check TLS configuration
echo ""
echo "Checking TLS configuration..."
TLS_SECRET=$(kubectl get ingress secure-ingress -n secure-app -o jsonpath='{.spec.tls[0].secretName}' 2>/dev/null || echo "")
if [ "$TLS_SECRET" == "tls-secret" ]; then
    echo -e "${GREEN}✓ TLS secret 'tls-secret' is configured${NC}"
else
    echo -e "${RED}✗ TLS secret should be 'tls-secret' (found: '$TLS_SECRET')${NC}"
    PASS=false
fi

# Check TLS hosts
TLS_HOST=$(kubectl get ingress secure-ingress -n secure-app -o jsonpath='{.spec.tls[0].hosts[0]}' 2>/dev/null || echo "")
if [ "$TLS_HOST" == "secure.example.com" ]; then
    echo -e "${GREEN}✓ TLS host 'secure.example.com' is configured${NC}"
else
    echo -e "${RED}✗ TLS host should be 'secure.example.com' (found: '$TLS_HOST')${NC}"
    PASS=false
fi

# Check host rule
echo ""
echo "Checking routing rules..."
RULE_HOST=$(kubectl get ingress secure-ingress -n secure-app -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
if [ "$RULE_HOST" == "secure.example.com" ]; then
    echo -e "${GREEN}✓ Host rule 'secure.example.com' is configured${NC}"
else
    echo -e "${RED}✗ Host rule should be 'secure.example.com' (found: '$RULE_HOST')${NC}"
    PASS=false
fi

# Check backend service
BACKEND_SVC=$(kubectl get ingress secure-ingress -n secure-app -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null || echo "")
if [ "$BACKEND_SVC" == "secure-service" ]; then
    echo -e "${GREEN}✓ Backend service 'secure-service' is configured${NC}"
else
    echo -e "${RED}✗ Backend service should be 'secure-service' (found: '$BACKEND_SVC')${NC}"
    PASS=false
fi

# Check backend port
BACKEND_PORT=$(kubectl get ingress secure-ingress -n secure-app -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}' 2>/dev/null || echo "")
if [ "$BACKEND_PORT" == "80" ]; then
    echo -e "${GREEN}✓ Backend port '80' is configured${NC}"
else
    echo -e "${RED}✗ Backend port should be '80' (found: '$BACKEND_PORT')${NC}"
    PASS=false
fi

# Check SSL redirect annotation
echo ""
echo "Checking SSL redirect annotations..."
SSL_REDIRECT=$(kubectl get ingress secure-ingress -n secure-app -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/ssl-redirect}' 2>/dev/null || echo "")
FORCE_SSL=$(kubectl get ingress secure-ingress -n secure-app -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/force-ssl-redirect}' 2>/dev/null || echo "")

if [ "$SSL_REDIRECT" == "true" ] || [ "$FORCE_SSL" == "true" ]; then
    echo -e "${GREEN}✓ SSL redirect annotation is configured${NC}"
else
    echo -e "${YELLOW}⚠ SSL redirect annotation recommended (ssl-redirect or force-ssl-redirect)${NC}"
fi

# Check output file
echo ""
echo "Checking output files..."
if [ -f "/opt/course/03/ingress.yaml" ]; then
    echo -e "${GREEN}✓ ingress.yaml saved to /opt/course/03/ingress.yaml${NC}"
else
    echo -e "${RED}✗ ingress.yaml not found at /opt/course/03/ingress.yaml${NC}"
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
