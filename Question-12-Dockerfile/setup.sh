#!/bin/bash
# Setup for Question 12 - Dockerfile and Deployment Security

set -e

echo "Setting up Question 12 - Dockerfile and Deployment Security..."

# Create output directory
mkdir -p /opt/course/12

# Create insecure Dockerfile
cat << 'EOF' > /opt/course/12/Dockerfile
FROM nginx:latest

ADD app.tar.gz /app
ADD config.txt /etc/config.txt
COPY index.html /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF

# Create insecure deployment
cat << 'EOF' > /opt/course/12/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        securityContext:
          privileged: true
          allowPrivilegeEscalation: true
EOF

echo ""
echo "✓ Environment ready!"
echo ""
echo "Files to analyze:"
echo "  - /opt/course/12/Dockerfile"
echo "  - /opt/course/12/deployment.yaml"
echo ""
echo "Common Dockerfile security issues:"
echo "  - Using :latest tag"
echo "  - Running as root"
echo "  - Using ADD instead of COPY for local files"
echo ""
echo "Common Deployment security issues:"
echo "  - privileged: true"
echo "  - allowPrivilegeEscalation: true"
echo "  - Not setting runAsNonRoot"
echo "  - Not setting readOnlyRootFilesystem"
