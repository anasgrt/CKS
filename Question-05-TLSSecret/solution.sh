#!/bin/bash
# Solution for Question 05 - Create TLS Secret

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Create TLS Secret"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Create the TLS secret"
echo "─────────────────────────────"
echo ""
cat << 'EOF'
kubectl create secret tls my-tls-secret \
    --cert=/opt/course/05/tls.crt \
    --key=/opt/course/05/tls.key \
    -n secure-ns
EOF

echo ""
echo "STEP 2: Verify the secret"
echo "─────────────────────────"
echo ""
cat << 'EOF'
# Check the secret exists
kubectl get secret my-tls-secret -n secure-ns

# Check secret details
kubectl describe secret my-tls-secret -n secure-ns

# View the secret type
kubectl get secret my-tls-secret -n secure-ns -o jsonpath='{.type}'
EOF

echo ""
echo "STEP 3: Save the command"
echo "────────────────────────"
echo ""
cat << 'EOF'
echo "kubectl create secret tls my-tls-secret --cert=/opt/course/05/tls.crt --key=/opt/course/05/tls.key -n secure-ns" > /opt/course/05/create-secret.txt
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "QUICK COMMANDS:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "kubectl create secret tls my-tls-secret --cert=/opt/course/05/tls.crt --key=/opt/course/05/tls.key -n secure-ns"
echo ""
echo "echo 'kubectl create secret tls my-tls-secret --cert=/opt/course/05/tls.crt --key=/opt/course/05/tls.key -n secure-ns' > /opt/course/05/create-secret.txt"
echo ""

echo "KEY POINTS:"
echo "  - TLS secrets have type 'kubernetes.io/tls'"
echo "  - They contain 'tls.crt' and 'tls.key' data fields"
echo "  - Use 'kubectl create secret tls' for easy creation"
echo "  - Certificate and key must be in PEM format"
