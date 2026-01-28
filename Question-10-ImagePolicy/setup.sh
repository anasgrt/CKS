#!/bin/bash
# Setup for Question 10 - ImagePolicyWebhook Admission Controller

set -e

echo "Setting up Question 10 - ImagePolicyWebhook..."

# Create output directory
mkdir -p /opt/course/10

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
