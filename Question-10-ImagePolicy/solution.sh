#!/bin/bash
# Solution for Question 10 - ImagePolicyWebhook Admission Controller

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Fix Incomplete ImagePolicyWebhook Configuration"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Review existing configuration files"
echo "────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Check what's already there
cat /etc/kubernetes/epconfig/admission_config.yaml
cat /etc/kubernetes/epconfig/kubeconfig.yaml
EOF

echo ""
echo "STEP 2: Fix admission_config.yaml - change defaultAllow to false"
echo "─────────────────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# The problem: defaultAllow is set to true (insecure!)
# Fix: Change defaultAllow from true to false

sudo sed -i 's/defaultAllow: true/defaultAllow: false/' /etc/kubernetes/epconfig/admission_config.yaml

# Or manually edit:
sudo vi /etc/kubernetes/epconfig/admission_config.yaml
# Change: defaultAllow: true
# To:     defaultAllow: false
EOF

echo ""
echo "STEP 3: Fix kubeconfig.yaml - set correct server URL and current-context"
echo "─────────────────────────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# The problems:
#   1. server URL is placeholder: https://EDIT_ME:443/image_policy
#   2. current-context is empty

# Fix the server URL
sudo sed -i 's|https://EDIT_ME:443/image_policy|https://image-policy-webhook.default.svc:443/image_policy|' /etc/kubernetes/epconfig/kubeconfig.yaml

# Fix the current-context
sudo sed -i 's/current-context: ""/current-context: default/' /etc/kubernetes/epconfig/kubeconfig.yaml

# Or manually edit:
sudo vi /etc/kubernetes/epconfig/kubeconfig.yaml
# Change server to: https://image-policy-webhook.default.svc:443/image_policy
# Change current-context to: default
EOF

echo ""
echo "STEP 4: Edit kube-apiserver manifest to enable ImagePolicyWebhook"
echo "──────────────────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml

# 1. Add ImagePolicyWebhook to --enable-admission-plugins:
    - --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook

# 2. Add the admission control config file flag:
    - --admission-control-config-file=/etc/kubernetes/epconfig/admission_config.yaml

# 3. Add volumeMount (in spec.containers[0].volumeMounts):
    - mountPath: /etc/kubernetes/epconfig
      name: epconfig
      readOnly: true

# 4. Add volume (in spec.volumes):
    - hostPath:
        path: /etc/kubernetes/epconfig
        type: DirectoryOrCreate
      name: epconfig
EOF

echo ""
echo "STEP 5: Wait for API server to restart"
echo "───────────────────────────────────────"
echo ""
cat << 'EOF'
# The API server will automatically restart when you save the manifest
# Wait and verify:

sleep 30
kubectl get nodes
kubectl get pods -n kube-system | grep api
EOF

echo ""
echo "STEP 6: Save corrected copies to /opt/course/10/"
echo "─────────────────────────────────────────────────"
echo ""
cat << 'EOF'
sudo mkdir -p /opt/course/10
sudo cp /etc/kubernetes/epconfig/admission_config.yaml /opt/course/10/
sudo cp /etc/kubernetes/epconfig/kubeconfig.yaml /opt/course/10/
EOF

echo ""
echo "STEP 7: Test the ImagePolicyWebhook (IMPORTANT!)"
echo "─────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Try to create a test pod - this SHOULD FAIL!
# Because defaultAllow=false and the webhook service doesn't exist,
# the API server will deny all pod creations (fail-closed behavior)

kubectl run test-pod --image=nginx 2>&1 | tee /opt/course/10/webhook-test.txt

# Expected error message should contain something like:
# "Error from server (Forbidden): pods "test-pod" is forbidden:
#  Post ... no endpoints available for service"
# OR
# "image policy webhook backend denied one or more images"

# This PROVES the ImagePolicyWebhook is working correctly!
# With defaultAllow: false, pods are denied when webhook is unreachable.

# Cleanup the test pod if it somehow got created (it shouldn't)
kubectl delete pod test-pod --ignore-not-found 2>/dev/null
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "CORRECTED CONFIGURATION FILES:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "admission_config.yaml (after fix):"
echo "-----------------------------------"
cat << 'EOF'
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
      defaultAllow: false    # <-- Changed from true to false
EOF

echo ""
echo "kubeconfig.yaml (after fix):"
echo "----------------------------"
cat << 'EOF'
apiVersion: v1
kind: Config
clusters:
- name: image-policy-webhook
  cluster:
    server: https://image-policy-webhook.default.svc:443/image_policy  # <-- Fixed URL
    insecure-skip-tls-verify: true
users:
- name: api-server
  user: {}
contexts:
- name: default
  context:
    cluster: image-policy-webhook
    user: api-server
current-context: default    # <-- Fixed: was empty ""
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "KEY POINTS FOR THE EXAM:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "1. defaultAllow setting is CRITICAL for security:"
echo "   - false = DENY pods if webhook unreachable (fail-closed, SECURE)"
echo "   - true  = ALLOW pods if webhook unreachable (fail-open, INSECURE)"
echo ""
echo "2. ⚠️  current-context MUST be set in the kubeconfig - VERY common mistake!"
echo "   - If current-context is empty or missing, the webhook will NOT work"
echo "   - PAY SPECIAL ATTENTION to this in the exam!"
echo "   - Required: current-context: default (not empty \"\")"
echo ""
echo "3. The webhook server URL format:"
echo "   https://<service-name>.<namespace>.svc:<port>/<path>"
echo ""
echo "4. Don't forget the volume and volumeMount in the API server manifest"
