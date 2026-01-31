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

# Verify serviceaccount.yaml
if [ -f "/opt/course/08/serviceaccount.yaml" ]; then
    if kubectl apply --dry-run=client -f /opt/course/08/serviceaccount.yaml &>/dev/null; then
        FILE_KIND=$(kubectl apply --dry-run=client -f /opt/course/08/serviceaccount.yaml -o jsonpath='{.kind}' 2>/dev/null)
        FILE_NAME=$(kubectl apply --dry-run=client -f /opt/course/08/serviceaccount.yaml -o jsonpath='{.metadata.name}' 2>/dev/null)
        FILE_NS=$(kubectl apply --dry-run=client -f /opt/course/08/serviceaccount.yaml -o jsonpath='{.metadata.namespace}' 2>/dev/null)
        FILE_AUTOMOUNT=$(kubectl apply --dry-run=client -f /opt/course/08/serviceaccount.yaml -o jsonpath='{.automountServiceAccountToken}' 2>/dev/null)

        if [ "$FILE_KIND" == "ServiceAccount" ] && [ "$FILE_NAME" == "backend-sa" ] && [ "$FILE_NS" == "secure" ]; then
            if [ "$FILE_AUTOMOUNT" == "false" ]; then
                echo -e "${GREEN}✓ serviceaccount.yaml is valid with automountServiceAccountToken: false${NC}"
            else
                echo -e "${RED}✗ serviceaccount.yaml missing automountServiceAccountToken: false${NC}"
                PASS=false
            fi
        else
            echo -e "${RED}✗ serviceaccount.yaml has incorrect content (Kind=$FILE_KIND, Name=$FILE_NAME, NS=$FILE_NS)${NC}"
            PASS=false
        fi
    else
        echo -e "${RED}✗ serviceaccount.yaml is not valid YAML${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ serviceaccount.yaml not found at /opt/course/08/serviceaccount.yaml${NC}"
    PASS=false
fi

# Verify deployment.yaml
if [ -f "/opt/course/08/deployment.yaml" ]; then
    if kubectl apply --dry-run=client -f /opt/course/08/deployment.yaml &>/dev/null; then
        FILE_KIND=$(kubectl apply --dry-run=client -f /opt/course/08/deployment.yaml -o jsonpath='{.kind}' 2>/dev/null)
        FILE_NAME=$(kubectl apply --dry-run=client -f /opt/course/08/deployment.yaml -o jsonpath='{.metadata.name}' 2>/dev/null)
        FILE_NS=$(kubectl apply --dry-run=client -f /opt/course/08/deployment.yaml -o jsonpath='{.metadata.namespace}' 2>/dev/null)

        if [ "$FILE_KIND" == "Deployment" ] && [ "$FILE_NAME" == "backend-deploy" ] && [ "$FILE_NS" == "secure" ]; then
            echo -e "${GREEN}✓ deployment.yaml is valid and correct${NC}"

            # Validate projected volume configuration in file
            FILE_JSON=$(kubectl apply --dry-run=client -f /opt/course/08/deployment.yaml -o json 2>/dev/null)
            HAS_PROJECTED=$(echo "$FILE_JSON" | jq '.spec.template.spec.volumes[] | select(.projected != null)' 2>/dev/null)
            if [ -n "$HAS_PROJECTED" ]; then
                echo -e "${GREEN}✓ deployment.yaml has projected volume configured${NC}"

                # Check for serviceAccountToken in projected volume
                HAS_SA_TOKEN=$(echo "$FILE_JSON" | jq '.spec.template.spec.volumes[].projected.sources[]? | select(.serviceAccountToken != null)' 2>/dev/null)
                if [ -n "$HAS_SA_TOKEN" ]; then
                    echo -e "${GREEN}✓ deployment.yaml has serviceAccountToken in projected volume${NC}"

                    # Check expirationSeconds
                    EXPIRATION=$(echo "$FILE_JSON" | jq -r '.spec.template.spec.volumes[].projected.sources[]? | select(.serviceAccountToken != null) | .serviceAccountToken.expirationSeconds' 2>/dev/null)
                    if [ -n "$EXPIRATION" ] && [ "$EXPIRATION" != "null" ]; then
                        echo -e "${GREEN}✓ Token expirationSeconds set to: ${EXPIRATION}s${NC}"
                    fi
                else
                    echo -e "${RED}✗ deployment.yaml missing serviceAccountToken in projected volume${NC}"
                    PASS=false
                fi
            else
                echo -e "${RED}✗ deployment.yaml missing projected volume${NC}"
                PASS=false
            fi
        else
            echo -e "${RED}✗ deployment.yaml has incorrect content (Kind=$FILE_KIND, Name=$FILE_NAME, NS=$FILE_NS)${NC}"
            PASS=false
        fi
    else
        echo -e "${RED}✗ deployment.yaml is not valid YAML${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ deployment.yaml not found at /opt/course/08/deployment.yaml${NC}"
    PASS=false
fi

# Check pod is running and token is mounted
echo ""
echo "Checking pod status and token mount..."
POD_NAME=$(kubectl get pods -n secure -l app=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
POD_STATUS=$(kubectl get pods -n secure -l app=backend -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "")

if [ "$POD_STATUS" == "Running" ]; then
    echo -e "${GREEN}✓ Backend pod is running${NC}"

    # Wait for pod to be fully ready
    if kubectl wait --for=condition=ready pod -l app=backend -n secure --timeout=10s &>/dev/null; then
        # Check if token file exists in the pod
        if kubectl exec -n secure "$POD_NAME" -- test -f /var/run/secrets/kubernetes.io/serviceaccount/token &>/dev/null; then
            echo -e "${GREEN}✓ Token file exists in pod at correct path${NC}"

            # Verify token is not empty
            TOKEN_SIZE=$(kubectl exec -n secure "$POD_NAME" -- wc -c /var/run/secrets/kubernetes.io/serviceaccount/token 2>/dev/null | awk '{print $1}')
            if [ -n "$TOKEN_SIZE" ] && [ "$TOKEN_SIZE" -gt 0 ]; then
                echo -e "${GREEN}✓ Token file is not empty (${TOKEN_SIZE} bytes)${NC}"
            else
                echo -e "${RED}✗ Token file is empty${NC}"
                PASS=false
            fi
        else
            echo -e "${RED}✗ Token file not found at /var/run/secrets/kubernetes.io/serviceaccount/token${NC}"
            PASS=false
        fi
    else
        echo -e "${YELLOW}⚠ Pod not ready yet, skipping token mount verification${NC}"
    fi
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
