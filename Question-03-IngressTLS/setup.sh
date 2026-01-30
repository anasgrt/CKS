#!/bin/bash
# Setup for Question 03 - Ingress with TLS and HTTP to HTTPS Redirect

set -e

echo "Setting up Question 03 - Ingress with TLS..."

# Create namespace
kubectl create namespace secure-app --dry-run=client -o yaml | kubectl apply -f -

# Generate self-signed TLS certificate
mkdir -p /tmp/tls-certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /tmp/tls-certs/tls.key \
    -out /tmp/tls-certs/tls.crt \
    -subj "/CN=secure.example.com/O=CKS-Exam" 2>/dev/null

# Create TLS secret
kubectl create secret tls tls-secret \
    --cert=/tmp/tls-certs/tls.crt \
    --key=/tmp/tls-certs/tls.key \
    -n secure-app \
    --dry-run=client -o yaml | kubectl apply -f -

# Create a ConfigMap with custom nginx config to show a welcome message
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: secure-app
data:
  default.conf: |
    server {
        listen 80;
        server_name secure.example.com;
        location / {
            default_type text/html;
            return 200 '<html><body><h1>Welcome to secure.example.com</h1><p>TLS Ingress is working correctly!</p></body></html>\n';
        }
    }
EOF

# Create a simple backend service and deployment with custom response
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: secure-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config
---
apiVersion: v1
kind: Service
metadata:
  name: secure-service
  namespace: secure-app
spec:
  selector:
    app: secure-app
  ports:
  - port: 80
    targetPort: 80
EOF

# Wait for deployment to be ready
echo "Waiting for backend deployment to be ready..."
kubectl rollout status deployment/secure-app -n secure-app --timeout=60s

# Check if ingress-nginx is installed, if not provide instructions
INGRESS_NS=""
if kubectl get namespace ingress-nginx &>/dev/null; then
    INGRESS_NS="ingress-nginx"
elif kubectl get namespace nginx-ingress &>/dev/null; then
    INGRESS_NS="nginx-ingress"
fi

if [ -z "$INGRESS_NS" ]; then
    echo ""
    echo "⚠ WARNING: Nginx Ingress Controller not detected!"
    echo "Install it with:"
    echo "  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml"
    echo ""
    echo "Or for bare-metal/kind:"
    echo "  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/baremetal/deploy.yaml"
fi

# Create output directory
mkdir -p /opt/course/03

# Clean up temp files
rm -rf /tmp/tls-certs

echo ""
echo "✓ Environment ready!"
echo ""
echo "Namespace: secure-app"
echo "TLS Secret: tls-secret"
echo "Backend Service: secure-service (port 80)"
echo ""
echo "Check resources with:"
echo "  kubectl get all -n secure-app"
echo "  kubectl get secret tls-secret -n secure-app"

# Get Ingress Controller IP for curl verification hint
if [ -n "$INGRESS_NS" ]; then
    INGRESS_IP=$(kubectl get svc -n $INGRESS_NS -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || \
                 kubectl get svc -n $INGRESS_NS -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].spec.clusterIP}' 2>/dev/null || echo "")
    if [ -n "$INGRESS_IP" ] && [ "$INGRESS_IP" != "null" ]; then
        echo ""
        echo "Ingress Controller IP: $INGRESS_IP"
        echo ""
        echo "After creating the Ingress, test with:"
        echo "  curl -k --resolve secure.example.com:443:$INGRESS_IP https://secure.example.com"
    else
        echo ""
        echo "Note: Could not auto-detect Ingress Controller IP."
        echo "After creating the Ingress, find the IP with:"
        echo "  kubectl get svc -n $INGRESS_NS"
        echo ""
        echo "Then test with:"
        echo "  curl -k --resolve secure.example.com:443:<INGRESS_IP> https://secure.example.com"
    fi
fi
