#!/bin/bash
# Reset Question 10 - ImagePolicyWebhook Admission Controller

rm -rf /opt/course/10

echo "Question 10 reset complete!"
echo ""
echo "⚠️  MANUAL CLEANUP REQUIRED (if you modified the API server):"
echo "   1. Edit /etc/kubernetes/manifests/kube-apiserver.yaml"
echo "   2. Remove ImagePolicyWebhook from --enable-admission-plugins"
echo "   3. Remove --admission-control-config-file flag"
echo "   4. Remove epconfig volume and volumeMount"
echo "   5. Wait 30-60s for API server to restart"
echo "   6. Optionally delete: sudo rm -rf /etc/kubernetes/epconfig"
