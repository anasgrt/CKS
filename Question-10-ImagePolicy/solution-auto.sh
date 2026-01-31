#!/bin/bash
# Automated solution for Question 10 - ImagePolicyWebhook Admission Controller
# This script actually implements the solution

set -e

echo "═══════════════════════════════════════════════════════════════════"
echo "Implementing ImagePolicyWebhook Configuration"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Step 1: Create the directory
echo "STEP 1: Creating /etc/kubernetes/epconfig directory..."
mkdir -p /etc/kubernetes/epconfig
echo "✓ Directory created"
echo ""

# Step 2: Create admission configuration file
echo "STEP 2: Creating admission_config.yaml..."
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
      defaultAllow: false
EOF
echo "✓ admission_config.yaml created"
echo ""

# Step 3: Create kubeconfig file
echo "STEP 3: Creating kubeconfig.yaml..."
cat << 'EOF' > /etc/kubernetes/epconfig/kubeconfig.yaml
apiVersion: v1
kind: Config
clusters:
- name: image-policy-webhook
  cluster:
    server: https://image-policy-webhook.default.svc:443/image_policy
    certificate-authority: /etc/kubernetes/epconfig/webhook-ca.crt
users:
- name: api-server
  user:
    client-certificate: /etc/kubernetes/epconfig/client.crt
    client-key: /etc/kubernetes/epconfig/client.key
contexts:
- name: default
  context:
    cluster: image-policy-webhook
    user: api-server
current-context: default
EOF
echo "✓ kubeconfig.yaml created"
echo ""

# Step 4: Backup kube-apiserver manifest
echo "STEP 4: Backing up kube-apiserver manifest..."
if [ ! -f /etc/kubernetes/manifests/kube-apiserver.yaml.q10.bak ]; then
    cp /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml.q10.bak
    echo "✓ Backup created"
else
    echo "✓ Backup already exists"
fi
echo ""

# Step 5: Update kube-apiserver manifest
echo "STEP 5: Updating kube-apiserver manifest..."

# Check if already configured
if grep -q "ImagePolicyWebhook" /etc/kubernetes/manifests/kube-apiserver.yaml; then
    echo "⚠ ImagePolicyWebhook already configured, skipping..."
else
    # Add ImagePolicyWebhook to admission plugins
    sed -i 's/--enable-admission-plugins=NodeRestriction/--enable-admission-plugins=NodeRestriction,ImagePolicyWebhook/' /etc/kubernetes/manifests/kube-apiserver.yaml

    # Add admission-control-config-file flag
    sed -i '/--enable-admission-plugins=NodeRestriction,ImagePolicyWebhook/a\    - --admission-control-config-file=/etc/kubernetes/epconfig/admission_config.yaml' /etc/kubernetes/manifests/kube-apiserver.yaml

    # Add volumeMount for epconfig
    sed -i '/mountPath: \/var\/log\/kubernetes\/audit/a\    - mountPath: /etc/kubernetes/epconfig\n      name: epconfig\n      readOnly: true' /etc/kubernetes/manifests/kube-apiserver.yaml

    # Add volume for epconfig
    sed -i '/path: \/var\/log\/kubernetes\/audit/{n;a\  - hostPath:\n      path: /etc/kubernetes/epconfig\n      type: DirectoryOrCreate\n    name: epconfig
}' /etc/kubernetes/manifests/kube-apiserver.yaml

    echo "✓ kube-apiserver manifest updated"
fi
echo ""

# Step 6: Copy files to /opt/course/10/
echo "STEP 6: Copying files to /opt/course/10/..."
mkdir -p /opt/course/10
cp /etc/kubernetes/epconfig/admission_config.yaml /opt/course/10/admission-config.yaml
cp /etc/kubernetes/epconfig/kubeconfig.yaml /opt/course/10/kubeconfig.yaml
echo "✓ Files copied"
echo ""

echo "═══════════════════════════════════════════════════════════════════"
echo "Configuration Complete!"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "The API server will automatically restart. Wait ~30 seconds."
echo ""
echo "Key Points:"
echo "  • defaultAllow: false = secure (fail-closed)"
echo "  • Server URL: https://image-policy-webhook.default.svc:443/image_policy"
echo "  • current-context must be set in kubeconfig"
echo ""
echo "To verify: kubectl get pods -n kube-system | grep kube-apiserver"
