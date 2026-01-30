#!/bin/bash
# Solution for Question 03 - Ingress with TLS and HTTP to HTTPS Redirect

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Ingress with TLS and HTTP to HTTPS Redirect"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Verify existing resources"
echo "──────────────────────────────────"
echo ""
cat << 'EOF'
# Check the TLS secret exists
kubectl get secret tls-secret -n secure-app

# Check the backend service exists
kubectl get svc secure-service -n secure-app

# Check the backend deployment is running
kubectl get pods -n secure-app
EOF

echo ""
echo "STEP 2: Create the Ingress manifest"
echo "────────────────────────────────────"
echo ""
cat << 'EOF'
# Create the Ingress YAML file
cat << 'INGRESS' > /opt/course/03/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
  namespace: secure-app
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - secure.example.com
    secretName: tls-secret
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: secure-service
            port:
              number: 80
INGRESS
EOF

echo ""
echo "STEP 3: Apply the Ingress"
echo "──────────────────────────"
echo ""
cat << 'EOF'
# Apply the ingress
kubectl apply -f /opt/course/03/ingress.yaml

# Verify the ingress was created
kubectl get ingress secure-ingress -n secure-app

# Check details
kubectl describe ingress secure-ingress -n secure-app
EOF

echo ""
echo "STEP 4: Verify with curl"
echo "─────────────────────────"
echo ""
cat << 'EOF'
# Get the Ingress Controller IP
# For LoadBalancer type:
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# If no LoadBalancer, use ClusterIP or NodePort:
# INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.clusterIP}')

# Or get the node IP and NodePort:
# NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
# NODE_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')

# Test HTTPS access with curl (skip cert verification since self-signed)
curl -k --resolve secure.example.com:443:$INGRESS_IP https://secure.example.com

# Expected output should contain:
# "Welcome to secure.example.com"

# Test HTTP to HTTPS redirect
curl -k -v --resolve secure.example.com:80:$INGRESS_IP http://secure.example.com 2>&1 | grep -i "location"
# Should show redirect to https://
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "COMPLETE INGRESS YAML:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

cat << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
  namespace: secure-app
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - secure.example.com
    secretName: tls-secret
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: secure-service
            port:
              number: 80
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "VERIFICATION COMMANDS:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
cat << 'EOF'
# Quick verification script
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || \
             kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.clusterIP}' 2>/dev/null)

echo "Testing HTTPS access to secure.example.com..."
curl -sk --resolve secure.example.com:443:$INGRESS_IP https://secure.example.com

# Verify response contains expected content
if curl -sk --resolve secure.example.com:443:$INGRESS_IP https://secure.example.com | grep -q "Welcome to secure.example.com"; then
    echo "✓ Curl verification successful!"
else
    echo "✗ Curl verification failed"
fi
EOF

echo ""
echo "KEY POINTS:"
echo "  - TLS section specifies the secret and hosts for HTTPS"
echo "  - ssl-redirect annotation forces HTTP to HTTPS redirect"
echo "  - pathType must be specified (Prefix, Exact, or ImplementationSpecific)"
echo "  - Backend uses service name and port number"
