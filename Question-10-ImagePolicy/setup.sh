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

# Create the epconfig directory structure (but leave it empty for the student)
mkdir -p /etc/kubernetes/epconfig

# Create backup of current kube-apiserver for reset purposes
cp /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml.q10.bak

echo ""
echo "✓ Environment ready!"
echo ""
echo "This question tests your knowledge of ImagePolicyWebhook configuration."
echo ""
echo "Key files to configure:"
echo "  1. /etc/kubernetes/epconfig/admission_config.yaml"
echo "  2. /etc/kubernetes/epconfig/kubeconfig.yaml"
echo "  3. /etc/kubernetes/manifests/kube-apiserver.yaml"
echo ""
echo "Important settings:"
echo "  - defaultAllow: false (fail-closed - secure)"
echo "  - defaultAllow: true (fail-open - insecure)"
echo ""
echo "API server flags to add:"
echo "  --enable-admission-plugins=...,ImagePolicyWebhook"
echo "  --admission-control-config-file=/etc/kubernetes/epconfig/admission_config.yaml"
