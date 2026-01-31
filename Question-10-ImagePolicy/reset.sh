#!/bin/bash
# Reset Question 10 - ImagePolicyWebhook Admission Controller

echo "Resetting Question 10 - ImagePolicyWebhook..."

# Remove output directory
rm -rf /opt/course/10

# Remove epconfig directory
rm -rf /etc/kubernetes/epconfig

# Restore original kube-apiserver if backup exists
if [ -f "/etc/kubernetes/manifests/kube-apiserver.yaml.q10.bak" ]; then
    echo "Restoring original kube-apiserver configuration..."
    cp /etc/kubernetes/manifests/kube-apiserver.yaml.q10.bak /etc/kubernetes/manifests/kube-apiserver.yaml

    echo "Waiting for API server to restart..."
    sleep 30

    # Wait for API server to be ready
    until kubectl get nodes &>/dev/null; do
        echo "Waiting for API server..."
        sleep 5
    done

    echo "✓ API server restarted successfully"
else
    echo "⚠️  No backup found - MANUAL CLEANUP REQUIRED:"
    echo "   1. Edit /etc/kubernetes/manifests/kube-apiserver.yaml"
    echo "   2. Remove ImagePolicyWebhook from --enable-admission-plugins"
    echo "   3. Remove --admission-control-config-file flag"
    echo "   4. Remove epconfig volume and volumeMount"
    echo "   5. Wait 30-60s for API server to restart"
fi

echo ""
echo "✓ Question 10 reset complete!"
