#!/bin/bash
# Solution for Question 11 - Pod Security Admission

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Pod Security Admission - Enforce Restricted Policy"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Switch to the correct context"
echo "──────────────────────────────────────"
echo ""
cat << 'EOF'
kubectl config use-context workload-prod
EOF

echo ""
echo "STEP 2: Use dry-run to identify violations (save output)"
echo "─────────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Run the dry-run command to preview policy violations without applying
kubectl label --dry-run=server --overwrite ns team-blue \
    pod-security.kubernetes.io/enforce=restricted 2>&1 | tee /opt/course/11/violations.txt

# The output will show warnings like:
# Warning: existing pods in namespace "team-blue" violate the new PodSecurity enforce level "restricted:latest"
# Warning: escalation-pod (and 1 other pod): allowPrivilegeEscalation != false, ...
# Warning: hostnetwork-pod: host namespaces, allowPrivilegeEscalation != false, ...
EOF

echo ""
echo "STEP 3: Save the kubectl label command used"
echo "────────────────────────────────────────────"
echo ""
cat << 'EOF'
echo 'kubectl label --overwrite ns team-blue pod-security.kubernetes.io/enforce=restricted' > /opt/course/11/command.txt
EOF

echo ""
echo "STEP 4: Apply the restricted policy to the namespace"
echo "─────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Now actually apply the label to enforce the restricted policy
kubectl label --overwrite ns team-blue pod-security.kubernetes.io/enforce=restricted

# Verify the label was applied
kubectl get ns team-blue --show-labels
EOF

echo ""
echo "STEP 5: Delete the non-compliant pods"
echo "─────────────────────────────────────"
echo ""
cat << 'EOF'
# Based on the warnings from Step 2, delete the non-compliant pods:

# Delete hostnetwork-pod (uses hostNetwork: true - violates restricted)
kubectl delete pod hostnetwork-pod -n team-blue

# Delete root-pod (no runAsNonRoot, no seccompProfile - violates restricted)
kubectl delete pod root-pod -n team-blue

# Delete escalation-pod (allowPrivilegeEscalation not set to false - violates restricted)
kubectl delete pod escalation-pod -n team-blue

# Save the list of deleted pods (one per line)
cat << 'DELETED' > /opt/course/11/deleted-pods.txt
hostnetwork-pod
root-pod
escalation-pod
DELETED
EOF

echo ""
echo "STEP 6: Verify compliant pod is still running"
echo "──────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Verify the compliant pod is still running
kubectl get pods -n team-blue

# Expected output: Only compliant-pod should remain Running

# Verify namespace has the PSA label
kubectl get ns team-blue --show-labels
# Should show: pod-security.kubernetes.io/enforce=restricted
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "POD SECURITY STANDARDS REFERENCE:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "LEVELS (least to most restrictive):"
echo "  1. privileged  - Unrestricted, allows everything"
echo "  2. baseline    - Prevents known privilege escalations"
echo "  3. restricted  - Heavily restricted, current best practices"
echo ""
echo "MODES:"
echo "  - enforce: Rejects pods that violate the policy"
echo "  - audit:   Logs violations in audit log, allows pods"
echo "  - warn:    Shows warnings to user, allows pods"
echo ""
echo "RESTRICTED POLICY REQUIREMENTS:"
echo "  - runAsNonRoot: true"
echo "  - allowPrivilegeEscalation: false"
echo "  - seccompProfile: RuntimeDefault or Localhost"
echo "  - capabilities: drop ALL"
echo "  - No hostNetwork, hostPID, hostIPC"
echo "  - No privileged containers"
echo ""
echo "KEY EXAM TIP:"
echo "  Use --dry-run=server first to identify violations,"
echo "  then apply the label and clean up non-compliant pods."
