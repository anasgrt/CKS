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
echo "Checking SSL redirect annotation..."
SSL_REDIRECT=$(kubectl get ingress secure-ingress -n secure-app -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/ssl-redirect}' 2>/dev/null || echo "")

if [ "$SSL_REDIRECT" == "true" ]; then
    echo -e "${GREEN}✓ SSL redirect annotation is configured${NC}"
else
    echo -e "${RED}✗ SSL redirect annotation (ssl-redirect: true) is required${NC}"
    PASS=false
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

# Curl verification
echo ""
echo "Checking connectivity with curl..."

# Find the Ingress Controller service
INGRESS_NS=""
if kubectl get namespace ingress-nginx &>/dev/null; then
    INGRESS_NS="ingress-nginx"
elif kubectl get namespace nginx-ingress &>/dev/null; then
    INGRESS_NS="nginx-ingress"
fi

if [ -n "$INGRESS_NS" ]; then
    # Try to get Ingress IP (LoadBalancer, then ClusterIP, then NodePort)
    INGRESS_IP=$(kubectl get svc -n $INGRESS_NS -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null)

    if [ -z "$INGRESS_IP" ]; then
        INGRESS_IP=$(kubectl get svc -n $INGRESS_NS -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].spec.clusterIP}' 2>/dev/null)
    fi

    if [ -z "$INGRESS_IP" ]; then
        # Try getting by service name directly
        INGRESS_IP=$(kubectl get svc -n $INGRESS_NS ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || \
                     kubectl get svc -n $INGRESS_NS ingress-nginx-controller -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
    fi

    if [ -n "$INGRESS_IP" ] && [ "$INGRESS_IP" != "null" ]; then
        echo "Using Ingress Controller IP: $INGRESS_IP"

        # Test HTTPS connectivity
        CURL_RESPONSE=$(curl -sk --connect-timeout 10 --resolve secure.example.com:443:$INGRESS_IP https://secure.example.com 2>/dev/null)

        if echo "$CURL_RESPONSE" | grep -q "Welcome to secure.example.com"; then
            echo -e "${GREEN}✓ Curl verification successful - received expected response${NC}"
        elif [ -n "$CURL_RESPONSE" ]; then
            echo -e "${YELLOW}⚠ Curl received response but not the expected content${NC}"
            echo "  Response preview: $(echo "$CURL_RESPONSE" | head -c 100)"
        else
            echo -e "${YELLOW}⚠ Curl could not connect to Ingress (this may be expected in some environments)${NC}"
        fi

        # Test HTTP to HTTPS redirect
        echo ""
        echo "Checking HTTP to HTTPS redirect..."
        REDIRECT_CHECK=$(curl -sk -o /dev/null -w '%{http_code}' --connect-timeout 10 --resolve secure.example.com:80:$INGRESS_IP http://secure.example.com 2>/dev/null)

        if [ "$REDIRECT_CHECK" == "308" ] || [ "$REDIRECT_CHECK" == "301" ] || [ "$REDIRECT_CHECK" == "302" ]; then
            echo -e "${GREEN}✓ HTTP to HTTPS redirect is working (status: $REDIRECT_CHECK)${NC}"
        elif [ -n "$REDIRECT_CHECK" ] && [ "$REDIRECT_CHECK" != "000" ]; then
            echo -e "${YELLOW}⚠ HTTP returned status $REDIRECT_CHECK (expected redirect 301/302/308)${NC}"
        else
            echo -e "${YELLOW}⚠ Could not verify HTTP redirect${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Could not determine Ingress Controller IP for curl test${NC}"
        echo "  Manual verification command:"
        echo "  curl -k --resolve secure.example.com:443:<INGRESS_IP> https://secure.example.com"
    fi
else
    echo -e "${YELLOW}⚠ Ingress Controller namespace not found (ingress-nginx or nginx-ingress)${NC}"
    echo "  Curl verification skipped. Ensure nginx ingress controller is installed."
fi

echo ""
echo "=============================================="
echo "Summary"
echo "=============================================="

if $PASS; then
    echo -e "${GREEN}All required checks passed!${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed.${NC}"
    exit 1
fi
