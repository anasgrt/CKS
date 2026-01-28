#!/bin/bash
# Reset Question 09 - Configure Kubernetes Auditing

kubectl delete namespace audit-test --ignore-not-found 2>/dev/null || true

rm -rf /opt/course/09

echo "Question 09 reset complete!"
echo ""
echo "⚠️  MANUAL CLEANUP REQUIRED (if you modified the API server):"
echo "   1. Edit /etc/kubernetes/manifests/kube-apiserver.yaml"
echo "   2. Remove these flags:"
echo "      --audit-policy-file"
echo "      --audit-log-path"
echo "      --audit-log-maxage"
echo "      --audit-log-maxbackup"
echo "   3. Remove audit-policy and audit-log volumes and volumeMounts"
echo "   4. Wait 30-60s for API server to restart"
echo "   5. Optionally delete: sudo rm -rf /etc/kubernetes/audit /var/log/kubernetes/audit"
