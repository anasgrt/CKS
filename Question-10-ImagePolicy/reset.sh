#!/bin/bash
# Reset Question 10 - ImagePolicyWebhook Admission Controller

echo "Resetting Question 10 - ImagePolicyWebhook..."

# Remove output directory
rm -rf /opt/course/10

# Remove epconfig directory completely
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

# Recreate the epconfig directory with incomplete configs (same as setup)
echo ""
echo "Recreating incomplete configuration files..."
mkdir -p /etc/kubernetes/epconfig

# Create INCOMPLETE admission_config.yaml (defaultAllow: true - insecure)
cat << 'EOF' > /etc/kubernetes/epconfig/admission_config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/epconfig/kubeconfig.yaml
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: true
EOF

# Create INCOMPLETE kubeconfig.yaml (placeholder URL, empty current-context)
cat << 'EOF' > /etc/kubernetes/epconfig/kubeconfig.yaml
apiVersion: v1
kind: Config
clusters:
- name: image-policy-webhook
  cluster:
    server: https://EDIT_ME:443/image_policy
    insecure-skip-tls-verify: true
users:
- name: api-server
  user: {}
contexts:
- name: default
  context:
    cluster: image-policy-webhook
    user: api-server
current-context: ""
EOF

# Recreate output directory
mkdir -p /opt/course/10

echo ""
echo "✓ Question 10 reset complete!"
echo ""
echo "Incomplete config files restored at /etc/kubernetes/epconfig/"
echo "  - admission_config.yaml (defaultAllow: true - needs fixing)"
echo "  - kubeconfig.yaml (placeholder URL - needs fixing)"
