#!/bin/bash
# Reset Question 03 - Ingress with TLS and HTTP to HTTPS Redirect

echo "Resetting Question 03 - Ingress with TLS..."

# Check if namespace exists before attempting cleanup
if kubectl get namespace secure-app &>/dev/null; then
    # Delete ingress first (depends on other resources)
    kubectl delete ingress secure-ingress -n secure-app --ignore-not-found 2>/dev/null || true

    # Delete deployment and its pods
    kubectl delete deployment secure-app -n secure-app --ignore-not-found 2>/dev/null || true

    # Delete the service
    kubectl delete service secure-service -n secure-app --ignore-not-found 2>/dev/null || true

    # Delete the ConfigMap
    kubectl delete configmap nginx-config -n secure-app --ignore-not-found 2>/dev/null || true

    # Delete the TLS secret
    kubectl delete secret tls-secret -n secure-app --ignore-not-found 2>/dev/null || true

    # Delete the namespace (this will also clean up any remaining resources)
    kubectl delete namespace secure-app --ignore-not-found 2>/dev/null || true

    echo "  - Kubernetes resources deleted"
else
    echo "  - Namespace secure-app does not exist, skipping Kubernetes cleanup"
fi

# Clean up output directory
rm -rf /opt/course/03
echo "  - Output directory /opt/course/03 removed"

# Clean up any leftover temp files
rm -rf /tmp/tls-certs
echo "  - Temp files cleaned up"

echo ""
echo "✓ Question 03 reset complete!"
