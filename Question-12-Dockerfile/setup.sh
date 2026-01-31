#!/bin/bash
# Setup for Question 12 - Dockerfile and Deployment Security

set -e

echo "Setting up Question 12 - Dockerfile and Deployment Security..."

# Create output directory
mkdir -p /opt/course/12

# Create insecure Dockerfile (with issues to fix)
cat << 'EOF' > /opt/course/12/Dockerfile
FROM ubuntu:latest
RUN apt-get update && apt-get install -y lsof wget nginx
ENV ENVIRONMENT=testing
COPY entrypoint.sh /
RUN useradd appuser
USER root
ENTRYPOINT ["/entrypoint.sh"]
EOF

# Create dummy entrypoint.sh file
cat << 'EOF' > /opt/course/12/entrypoint.sh
#!/bin/bash
echo "Application starting..."
sleep 3600
EOF
chmod +x /opt/course/12/entrypoint.sh

# Create namespace for deployment
kubectl create namespace team-blue --dry-run=client -o yaml | kubectl apply -f -

# Create insecure deployment (with issues to fix)
cat << 'EOF' > /opt/course/12/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kafka
  namespace: team-blue
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
      - name: kafka
        image: bitnami/kafka:3.4
        securityContext:
          capabilities:
            add: ['NET_ADMIN']
            drop: ['all']
          privileged: true
          readOnlyRootFilesystem: false
          runAsUser: 65535
        ports:
        - containerPort: 9092
EOF

echo ""
echo "✓ Environment ready!"
echo ""
echo "Files to analyze and fix:"
echo "  - /opt/course/12/Dockerfile"
echo "  - /opt/course/12/deployment.yaml"
echo ""
echo "Remember:"
echo "  - Fix EXACTLY 2 issues per file"
echo "  - Only MODIFY existing settings (don't add new ones)"
echo "  - Use 'nobody' user (UID 65535) for Dockerfile"
echo "  - Edit files in place (don't create -fixed files)"
