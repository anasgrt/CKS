#!/bin/bash
# Reset Question 13 - Kubelet Security Configuration

rm -rf /opt/course/13

echo "Question 13 reset complete!"
echo ""
echo "⚠️  MANUAL CLEANUP REQUIRED (if you modified kubelet on a node):"
echo "   SSH to the node and:"
echo "   1. Restore /var/lib/kubelet/config.yaml from backup, or set:"
echo "      authentication.anonymous.enabled: true  (original insecure)"
echo "      authorization.mode: AlwaysAllow  (original insecure)"
echo "   2. Restart kubelet: sudo systemctl restart kubelet"
echo "   3. Verify node: kubectl get nodes"
