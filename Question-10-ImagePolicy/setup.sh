#!/bin/bash
# Setup for Question 10 - ImagePolicyWebhook Admission Controller

set -e

echo "Setting up Question 10 - ImagePolicyWebhook..."

# Clean up any previous attempts
rm -rf /opt/course/10
rm -rf /etc/kubernetes/epconfig

# Restore original kube-apiserver if backup exists (from previous attempt)
if [ -f "/etc/kubernetes/manifests/kube-apiserver.yaml.q10.bak" ]; then
    echo "Cleaning up previous attempt - restoring API server..."
    cp /etc/kubernetes/manifests/kube-apiserver.yaml.q10.bak /etc/kubernetes/manifests/kube-apiserver.yaml
    sleep 30
fi

# Create output directory
mkdir -p /opt/course/10

# Create the epconfig directory structure
mkdir -p /etc/kubernetes/epconfig

# Create backup of current kube-apiserver for reset purposes (only if doesn't exist)
if [ ! -f "/etc/kubernetes/manifests/kube-apiserver.yaml.q10.bak" ]; then
    cp /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml.q10.bak
    echo "Created clean backup of kube-apiserver manifest"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Create INCOMPLETE/MISCONFIGURED admission_config.yaml
# Issues to fix:
#   - defaultAllow is set to TRUE (insecure - should be false)
# ══════════════════════════════════════════════════════════════════════════════
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

# ══════════════════════════════════════════════════════════════════════════════
# Create INCOMPLETE kubeconfig.yaml for the webhook
# Issues to fix:
#   - server URL is a placeholder (EDIT_ME)
#   - current-context is missing/empty
# ══════════════════════════════════════════════════════════════════════════════
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

echo ""
echo "✓ Environment ready!"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "SCENARIO: A previous admin left incomplete ImagePolicyWebhook configuration"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "Existing configuration files (need fixing):"
echo "  • /etc/kubernetes/epconfig/admission_config.yaml"
echo "  • /etc/kubernetes/epconfig/kubeconfig.yaml"
echo ""
echo "Your task:"
echo "  1. Review and fix the configuration files"
echo "  2. Enable ImagePolicyWebhook in the API server"
echo "  3. Save corrected copies to /opt/course/10/"
echo ""
echo "Hint: Check defaultAllow setting and the webhook server URL"
