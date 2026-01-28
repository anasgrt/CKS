#!/bin/bash
# Solution for Question 10 - ImagePolicyWebhook Admission Controller

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: ImagePolicyWebhook Admission Controller Setup"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Create the admission configuration directory"
echo "─────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
sudo mkdir -p /etc/kubernetes/epconfig
EOF

echo ""
echo "STEP 2: Create the admission configuration file"
echo "────────────────────────────────────────────────"
echo ""
cat << 'EOF'
cat << 'ADMISSION' | sudo tee /etc/kubernetes/epconfig/admission_config.yaml
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
ADMISSION
EOF

echo ""
echo "STEP 3: Create the kubeconfig for the webhook"
echo "──────────────────────────────────────────────"
echo ""
cat << 'EOF'
cat << 'KUBECONFIG' | sudo tee /etc/kubernetes/epconfig/kubeconfig.yaml
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
KUBECONFIG
EOF

echo ""
echo "STEP 4: Edit kube-apiserver manifest"
echo "─────────────────────────────────────"
echo ""
cat << 'EOF'
# Backup the manifest
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml.bak

# Edit the manifest
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml

# Add to --enable-admission-plugins (append ImagePolicyWebhook):
    - --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook

# Add this new flag:
    - --admission-control-config-file=/etc/kubernetes/epconfig/admission_config.yaml

# Add volumeMount:
    - mountPath: /etc/kubernetes/epconfig
      name: epconfig
      readOnly: true

# Add volume:
    - hostPath:
        path: /etc/kubernetes/epconfig
        type: DirectoryOrCreate
      name: epconfig
EOF

echo ""
echo "STEP 5: Save copies to /opt/course/10/"
echo "───────────────────────────────────────"
echo ""
cat << 'EOF'
sudo mkdir -p /opt/course/10
sudo cp /etc/kubernetes/epconfig/admission_config.yaml /opt/course/10/
sudo cp /etc/kubernetes/epconfig/kubeconfig.yaml /opt/course/10/
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "KEY POINTS FOR THE EXAM:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "1. The kubeconfig MUST have 'current-context' set - very common mistake!"
echo ""
echo "2. 'defaultAllow: false' is the secure setting (fail-closed):"
echo "   - false = DENY pods if webhook unreachable (secure)"
echo "   - true  = ALLOW pods if webhook unreachable (insecure)"
echo ""
echo "3. The ImagePolicyWebhook uses a kubeconfig-style file to configure:"
echo "   - Which webhook server to contact (clusters.cluster.server)"
echo "   - How to authenticate (users.user with client certs)"
echo ""
echo "4. Don't forget to add volumes and volumeMounts to API server"
