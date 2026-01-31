#!/bin/bash
# Solution for Question 12 - Dockerfile and Deployment Security

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Dockerfile and Deployment Security - Fix 2 Issues Each"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "PART 1: DOCKERFILE ISSUES"
echo "═════════════════════════"
echo ""
echo "Original Dockerfile at /opt/course/12/Dockerfile:"
echo ""
cat << 'EOF'
FROM ubuntu:latest          ← ISSUE 1: Using 'latest' tag (not specific)
RUN apt-get update && apt-get install -y lsof wget nginx
ENV ENVIRONMENT=testing
COPY entrypoint.sh /
RUN useradd appuser
USER root                   ← ISSUE 2: Running as root user
ENTRYPOINT ["/entrypoint.sh"]
EOF

echo ""
echo "─────────────────────────────────────────────────────────────────"
echo "FIX for Dockerfile (modify 2 lines):"
echo "─────────────────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
Line 1: FROM ubuntu:latest  →  FROM ubuntu:16.04
        Reason: Never use 'latest' tag; use specific version for reproducibility

Line 6: USER root  →  USER nobody
        Reason: Never run as root; use unprivileged user (nobody = UID 65535)
EOF

echo ""
echo "Commands to fix the Dockerfile:"
echo ""
cat << 'EOF'
# Fix Line 1: Change ubuntu:latest to ubuntu:16.04
sed -i 's/ubuntu:latest/ubuntu:16.04/' /opt/course/12/Dockerfile

# Fix Line 6: Change USER root to USER nobody
sed -i 's/USER root/USER nobody/' /opt/course/12/Dockerfile

# Verify the changes
cat /opt/course/12/Dockerfile
EOF

echo ""
echo ""
echo "PART 2: DEPLOYMENT ISSUES"
echo "═════════════════════════"
echo ""
echo "Original Deployment at /opt/course/12/deployment.yaml:"
echo ""
cat << 'EOF'
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
          privileged: true              ← ISSUE 1: Container runs in privileged mode
          readOnlyRootFilesystem: false ← ISSUE 2: Filesystem is writable
          runAsUser: 65535
        ports:
        - containerPort: 9092
EOF

echo ""
echo "─────────────────────────────────────────────────────────────────"
echo "FIX for Deployment (modify 2 fields):"
echo "─────────────────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
Field 1: privileged: true  →  privileged: false
         Reason: Containers should never run in privileged mode (full host access)

Field 2: readOnlyRootFilesystem: false  →  readOnlyRootFilesystem: true
         Reason: Container filesystem should be immutable (security best practice)
EOF

echo ""
echo "Commands to fix the Deployment:"
echo ""
cat << 'EOF'
# Fix privileged: true → false
sed -i 's/privileged: true/privileged: false/' /opt/course/12/deployment.yaml

# Fix readOnlyRootFilesystem: false → true
sed -i 's/readOnlyRootFilesystem: false/readOnlyRootFilesystem: true/' /opt/course/12/deployment.yaml

# Verify the changes
cat /opt/course/12/deployment.yaml

# Apply the fixed deployment
kubectl apply -f /opt/course/12/deployment.yaml
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "SUMMARY OF CHANGES:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "DOCKERFILE (2 changes):"
echo "  ✓ Line 1: FROM ubuntu:latest → FROM ubuntu:16.04"
echo "  ✓ Line 6: USER root → USER nobody"
echo ""
echo "DEPLOYMENT (2 changes):"
echo "  ✓ privileged: true → privileged: false"
echo "  ✓ readOnlyRootFilesystem: false → readOnlyRootFilesystem: true"
echo ""
echo "KEY EXAM TIPS:"
echo "  - Read constraints carefully (fix EXACTLY 2 issues per file)"
echo "  - Only MODIFY existing settings (don't add new ones)"
echo "  - Use 'nobody' (UID 65535) when unprivileged user is needed"
echo "  - Edit files in place (don't create -fixed versions)"
