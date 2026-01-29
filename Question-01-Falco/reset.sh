#!/bin/bash
# Reset Question 01 - Falco Runtime Security Detection

set -e

echo "Resetting Question 01 - Falco Runtime Security..."

# Delete deployments and namespace
kubectl delete deployment nvidia-gpu cpu ollama -n apps --ignore-not-found 2>/dev/null || true
kubectl delete namespace apps --ignore-not-found 2>/dev/null || true

# Clean up output directory
rm -rf /opt/course/01

# Remove custom Falco rule (but keep Falco installed for other exercises)
sudo rm -f /etc/falco/rules.d/dev_mem_access.yaml 2>/dev/null || true

# Restart Falco to remove the custom rule
if systemctl is-active --quiet falco 2>/dev/null; then
    sudo systemctl restart falco 2>/dev/null || true
fi

echo "✓ Question 01 reset complete!"
echo ""
echo "Note: Falco remains installed (may be needed for other questions)"
