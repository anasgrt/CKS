#!/bin/bash
# Solution for Question 12 - Dockerfile and Deployment Security

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Dockerfile and Deployment Security Best Practices"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "ISSUES IN ORIGINAL DOCKERFILE:"
echo "───────────────────────────────"
echo ""
cat << 'EOF'
1. FROM nginx:latest  <- Using :latest tag (should use specific version)
2. ADD app.tar.gz     <- ADD is OK for archives that need extraction
3. ADD config.txt     <- Should use COPY for regular files
4. No USER instruction <- Runs as root by default
EOF

echo ""
echo "FIXED DOCKERFILE:"
echo "─────────────────"
echo ""
cat << 'EOF'
cat << 'DOCKERFILE' > /opt/course/12/Dockerfile-fixed
FROM nginx:1.25.3-alpine

# Use COPY for local files that don't need extraction
COPY config.txt /etc/config.txt
COPY index.html /usr/share/nginx/html/

# ADD is acceptable for archives that need extraction
ADD app.tar.gz /app

# Create non-root user and set ownership
RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -G appgroup -D appuser && \
    chown -R appuser:appgroup /usr/share/nginx/html /var/cache/nginx /var/run

# Run as non-root user
USER appuser

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
DOCKERFILE
EOF

echo ""
echo "ISSUES IN ORIGINAL DEPLOYMENT:"
echo "──────────────────────────────"
echo ""
cat << 'EOF'
1. image: nginx:latest      <- Using :latest tag
2. privileged: true         <- Container has full host access
3. allowPrivilegeEscalation: true <- Can gain more privileges
4. No runAsNonRoot          <- Can run as root
5. No readOnlyRootFilesystem <- Filesystem is writable
EOF

echo ""
echo "FIXED DEPLOYMENT:"
echo "─────────────────"
echo ""
cat << 'EOF'
cat << 'DEPLOYMENT' > /opt/course/12/deployment-fixed.yaml
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
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
      - name: nginx
        image: nginx:1.25.3-alpine
        ports:
        - containerPort: 80
        securityContext:
          privileged: false
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /var/cache/nginx
        - name: run
          mountPath: /var/run
      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
      - name: run
        emptyDir: {}
DEPLOYMENT
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "KEY SECURITY BEST PRACTICES:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "DOCKERFILE:"
echo "  - Use specific image tags (not :latest)"
echo "  - Use COPY instead of ADD for local files"
echo "  - Run as non-root user (USER instruction)"
echo "  - Minimize layers and packages"
echo ""
echo "DEPLOYMENT:"
echo "  - privileged: false"
echo "  - allowPrivilegeEscalation: false"
echo "  - runAsNonRoot: true"
echo "  - readOnlyRootFilesystem: true"
echo "  - Drop ALL capabilities"
echo "  - Use emptyDir for writable directories"
