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
echo "KEY POINTS:"
echo "  - TLS section specifies the secret and hosts for HTTPS"
echo "  - ssl-redirect annotation forces HTTP to HTTPS redirect"
echo "  - pathType must be specified (Prefix, Exact, or ImplementationSpecific)"
echo "  - Backend uses service name and port number"
