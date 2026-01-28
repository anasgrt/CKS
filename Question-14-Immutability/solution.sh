#!/bin/bash
# Solution for Question 14 - Ensure Immutability of Containers at Runtime

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Ensure Immutability of Containers at Runtime"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: First, try adding readOnlyRootFilesystem (it will fail)"
echo "─────────────────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Edit deployment
kubectl edit deployment nginx -n immutable-ns

# Add to container's securityContext:
        securityContext:
          readOnlyRootFilesystem: true

# The pod will crash - check logs
kubectl logs -n immutable-ns -l app=nginx
# Error: cannot create /var/cache/nginx - Read-only file system
EOF

echo ""
echo "STEP 2: Add emptyDir volumes for writable directories"
echo "──────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Edit deployment again
kubectl edit deployment nginx -n immutable-ns

# Add volumes and volumeMounts (see complete manifest below)
EOF

echo ""
echo "STEP 3: Apply the complete fixed deployment"
echo "────────────────────────────────────────────"
echo ""
cat << 'EOF'
cat << 'DEPLOY' > /opt/course/14/deployment-immutable.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: immutable-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        securityContext:
          readOnlyRootFilesystem: true
        volumeMounts:
        - name: cache
          mountPath: /var/cache/nginx
        - name: run
          mountPath: /var/run
        - name: tmp
          mountPath: /tmp
      volumes:
      - name: cache
        emptyDir: {}
      - name: run
        emptyDir: {}
      - name: tmp
        emptyDir: {}
DEPLOY

kubectl apply -f /opt/course/14/deployment-immutable.yaml
EOF

echo ""
echo "STEP 4: Verify the pod is running"
echo "──────────────────────────────────"
echo ""
cat << 'EOF'
# Wait for rollout
kubectl rollout status deployment nginx -n immutable-ns

# Check pod status
kubectl get pods -n immutable-ns

# Verify filesystem is read-only
kubectl exec -n immutable-ns deployment/nginx -- touch /test-file
# Should fail: Read-only file system

# But writable directories work
kubectl exec -n immutable-ns deployment/nginx -- touch /tmp/test-file
# Should succeed
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "COMPLETE IMMUTABLE DEPLOYMENT:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
cat << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: immutable-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        securityContext:
          readOnlyRootFilesystem: true
        volumeMounts:
        - name: cache
          mountPath: /var/cache/nginx
        - name: run
          mountPath: /var/run
        - name: tmp
          mountPath: /tmp
      volumes:
      - name: cache
        emptyDir: {}
      - name: run
        emptyDir: {}
      - name: tmp
        emptyDir: {}
EOF

echo ""
echo "KEY POINTS:"
echo "  - readOnlyRootFilesystem: true makes container filesystem immutable"
echo "  - Applications may need writable directories (logs, caches, PIDs)"
echo "  - Use emptyDir volumes for required writable paths"
echo "  - Check container logs to identify needed writable paths"
echo ""
echo "COMMON WRITABLE PATHS:"
echo "  - nginx: /var/cache/nginx, /var/run"
echo "  - apache: /var/run/apache2, /var/lock/apache2"
echo "  - java: /tmp"
echo "  - python: /tmp, application-specific paths"
