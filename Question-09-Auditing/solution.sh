#!/bin/bash
# Solution for Question 09 - Configure Kubernetes Auditing

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Configure Kubernetes Auditing"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Create audit directories"
echo "────────────────────────────────"
echo ""
cat << 'EOF'
sudo mkdir -p /etc/kubernetes/audit
sudo mkdir -p /var/log/kubernetes/audit
EOF

echo ""
echo "STEP 2: Create the audit policy file"
echo "─────────────────────────────────────"
echo ""
cat << 'EOF'
cat << 'POLICY' | sudo tee /etc/kubernetes/audit/policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  # Log secrets at Metadata level
  - level: Metadata
    resources:
    - group: ""
      resources: ["secrets"]

  # Log configmaps at Metadata level
  - level: Metadata
    resources:
    - group: ""
      resources: ["configmaps"]

  # Log namespaces at RequestResponse level
  - level: RequestResponse
    resources:
    - group: ""
      resources: ["namespaces"]

  # Default: log all other resources at Metadata
  - level: Metadata
    omitStages:
    - RequestReceived
POLICY
EOF

echo ""
echo "STEP 3: Backup and edit kube-apiserver manifest"
echo "────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Backup the manifest
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml.bak

# Edit the manifest
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml

# Add these flags to the command section:
    - --audit-policy-file=/etc/kubernetes/audit/policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit/audit.log
    - --audit-log-maxage=2
    - --audit-log-maxbackup=10

# Add these volumeMounts:
    - mountPath: /etc/kubernetes/audit
      name: audit-policy
      readOnly: true
    - mountPath: /var/log/kubernetes/audit
      name: audit-log

# Add these volumes:
    - hostPath:
        path: /etc/kubernetes/audit
        type: DirectoryOrCreate
      name: audit-policy
    - hostPath:
        path: /var/log/kubernetes/audit
        type: DirectoryOrCreate
      name: audit-log
EOF

echo ""
echo "STEP 4: Wait for API server to restart"
echo "───────────────────────────────────────"
echo ""
cat << 'EOF'
# Wait 30-60 seconds for the API server to restart
sleep 30

# Verify API server is running
kubectl get pods -n kube-system -l component=kube-apiserver

# If it's not starting, check logs:
sudo cat /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/*.log | tail -50
EOF

echo ""
echo "STEP 5: Save the audit policy"
echo "─────────────────────────────"
echo ""
cat << 'EOF'
cp /etc/kubernetes/audit/policy.yaml /opt/course/09/audit-policy.yaml
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "COMPLETE AUDIT POLICY:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
cat << 'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  - level: Metadata
    resources:
    - group: ""
      resources: ["secrets"]

  - level: Metadata
    resources:
    - group: ""
      resources: ["configmaps"]

  - level: RequestResponse
    resources:
    - group: ""
      resources: ["namespaces"]

  - level: Metadata
    omitStages:
    - RequestReceived
EOF

echo ""
echo "API SERVER FLAGS TO ADD:"
echo "  --audit-policy-file=/etc/kubernetes/audit/policy.yaml"
echo "  --audit-log-path=/var/log/kubernetes/audit/audit.log"
echo "  --audit-log-maxage=2"
echo "  --audit-log-maxbackup=10"
echo ""
echo "⚠️  CRITICAL WARNINGS - COMMON MISTAKES:"
echo "  ❌ DO NOT mount individual files (e.g., /etc/kubernetes/audit/policy.yaml)"
echo "  ❌ DO NOT mount /var/log/kubernetes/audit/audit.log directly"
echo "  ✅ ALWAYS mount DIRECTORIES:"
echo "     - mountPath: /etc/kubernetes/audit (readOnly: true)"
echo "     - mountPath: /var/log/kubernetes/audit (readOnly: false or omit)"
echo "  ❌ DO NOT set readOnly: true on /var/log/kubernetes/audit"
echo "  ✅ API server must WRITE to audit log directory"
echo ""
echo "KEY POINTS:"
echo "  - Audit levels: None < Metadata < Request < RequestResponse"
echo "  - group: '' means core API group (pods, secrets, etc.)"
echo "  - API server will restart automatically when manifest changes"
echo "  - Check /var/log/kubernetes/audit/audit.log for audit events"
echo "  - If API server fails to start, check: crictl logs <container-id>"
echo "  - Error 'is a directory' means you mounted a file instead of directory"
