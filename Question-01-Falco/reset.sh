#!/bin/bash
# Reset Question 01 - Falco Runtime Security Detection

set -e

echo "Resetting Question 01 - Falco Runtime Security..."

# Delete deployments and namespace for the question
kubectl delete deployment nvidia-gpu cpu ollama -n apps --ignore-not-found 2>/dev/null || true
kubectl delete namespace apps --ignore-not-found 2>/dev/null || true

# Clean up output directory
rm -rf /opt/course/01

# Remove custom Falco rules from worker nodes (keep Falco installed)
echo "Removing custom Falco rules from worker nodes..."
WORKER_NODES=$(kubectl get nodes --no-headers -o custom-columns=":metadata.name" | grep -v "cplane\|control\|master" || true)
for NODE in $WORKER_NODES; do
    echo "Cleaning Falco rules on $NODE..."
    ssh -o StrictHostKeyChecking=no "$NODE" "rm -f /etc/falco/rules.d/dev_mem_access.yaml 2>/dev/null; systemctl restart falco-modern-bpf 2>/dev/null || systemctl restart falco 2>/dev/null || true" 2>/dev/null || true
done

echo "✓ Question 01 reset complete!"
echo ""
echo "Note: Falco service remains installed on worker nodes (may be needed for other questions)"
