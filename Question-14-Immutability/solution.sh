#!/bin/bash
# Solution for Question 14 - Ensure Immutability of Containers at Runtime

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Ensure Immutability of Containers at Runtime"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "═══════════════════════════════════════════════════════════════════"
echo "TASK 1: Make nginx Container Immutable"
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
echo "STEP 4: Verify the nginx pod is running"
echo "────────────────────────────────────────"
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
echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "TASK 2: Harden lamp-deployment Security Context"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Export and edit lamp-deployment"
echo "────────────────────────────────────────"
echo ""
cat << 'EOF'
# Export current deployment
kubectl get deployment lamp-deployment -n lamp -o yaml > /opt/course/14/lamp-deployment.yaml

# Edit the file to add securityContext
vi /opt/course/14/lamp-deployment.yaml
EOF

echo ""
echo "STEP 2: Apply security context configuration"
echo "─────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Add securityContext to container spec:
        securityContext:
          runAsUser: 20000
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false

# Apache needs writable directories - add emptyDir volumes:
        volumeMounts:
        - name: apache-run
          mountPath: /var/run/apache2
        - name: apache-lock
          mountPath: /var/lock/apache2
        - name: tmp
          mountPath: /tmp

      volumes:
      - name: apache-run
        emptyDir: {}
      - name: apache-lock
        emptyDir: {}
      - name: tmp
        emptyDir: {}
EOF

echo ""
echo "STEP 3: Complete lamp-deployment manifest"
echo "──────────────────────────────────────────"
echo ""
cat << 'EOF'
cat << 'DEPLOY' > /opt/course/14/lamp-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lamp-deployment
  namespace: lamp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: lamp
  template:
    metadata:
      labels:
        app: lamp
    spec:
      containers:
      - name: lamp
        image: php:8.2-apache
        ports:
        - containerPort: 80
        securityContext:
          runAsUser: 20000
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
        volumeMounts:
        - name: apache-run
          mountPath: /var/run/apache2
        - name: apache-lock
          mountPath: /var/lock/apache2
        - name: tmp
          mountPath: /tmp
      volumes:
      - name: apache-run
        emptyDir: {}
      - name: apache-lock
        emptyDir: {}
      - name: tmp
        emptyDir: {}
DEPLOY

kubectl apply -f /opt/course/14/lamp-deployment.yaml
EOF

echo ""
echo "STEP 4: Verify lamp-deployment"
echo "───────────────────────────────"
echo ""
cat << 'EOF'
# Wait for rollout
kubectl rollout status deployment lamp-deployment -n lamp

# Check pod status
kubectl get pods -n lamp

# Verify security context
kubectl get deployment lamp-deployment -n lamp -o jsonpath='{.spec.template.spec.containers[0].securityContext}' | jq

# Verify user ID
kubectl exec -n lamp deployment/lamp-deployment -- id
# Should show: uid=20000

# Verify read-only filesystem
kubectl exec -n lamp deployment/lamp-deployment -- touch /test-file
# Should fail: Read-only file system

# Verify no privilege escalation
kubectl get deployment lamp-deployment -n lamp -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}'
# Should show: false
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "SUMMARY"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "Security hardening applied:"
echo "  Task 1 - nginx:"
echo "    ✓ readOnlyRootFilesystem: true"
echo "    ✓ emptyDir volumes for /var/cache/nginx, /var/run, /tmp"
echo ""
echo "  Task 2 - lamp-deployment:"
echo "    ✓ runAsUser: 20000"
echo "    ✓ readOnlyRootFilesystem: true"
echo "    ✓ allowPrivilegeEscalation: false"
echo "    ✓ emptyDir volumes for Apache writable paths"
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
