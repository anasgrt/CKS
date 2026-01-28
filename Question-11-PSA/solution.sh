#!/bin/bash
# Solution for Question 11 - Pod Security Admission

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Pod Security Admission - Identify and Delete Non-Compliant Pods"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Use dry-run to identify violations"
echo "───────────────────────────────────────────"
echo ""
cat << 'EOF'
# Run the dry-run command to see what would violate the restricted policy
kubectl label --dry-run=server --overwrite ns team-blue \
    pod-security.kubernetes.io/enforce=restricted 2>&1 | tee /opt/course/11/violations.txt

# The output will show warnings like:
# Warning: existing pods in namespace "team-blue" violate the new PodSecurity enforce level "restricted:latest"
# Warning: privileged-pod: privileged, ...
# Warning: root-pod: runAsNonRoot != true, ...
EOF

echo ""
echo "STEP 2: Save the command used"
echo "─────────────────────────────"
echo ""
cat << 'EOF'
echo 'kubectl label --dry-run=server --overwrite ns team-blue pod-security.kubernetes.io/enforce=restricted' > /opt/course/11/command.txt
EOF

echo ""
echo "STEP 3: Identify and delete non-compliant pods"
echo "───────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Based on the warnings, delete the non-compliant pods:

# Delete hostnetwork-pod (uses hostNetwork: true)
kubectl delete pod hostnetwork-pod -n team-blue

# Delete root-pod (no runAsNonRoot, no seccompProfile)
kubectl delete pod root-pod -n team-blue

# Delete escalation-pod (allowPrivilegeEscalation not set to false)
kubectl delete pod escalation-pod -n team-blue

# Save the list of deleted pods
cat << 'DELETED' > /opt/course/11/deleted-pods.txt
hostnetwork-pod
root-pod
escalation-pod
DELETED
EOF

echo ""
echo "STEP 4: Verify compliant pod is still running"
echo "──────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Verify the compliant pod is still running
kubectl get pods -n team-blue

# Should show only: compliant-pod   Running
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "POD SECURITY STANDARDS LEVELS:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "1. PRIVILEGED"
echo "   - Unrestricted policy"
echo "   - Allows everything"
echo ""
echo "2. BASELINE"
echo "   - Minimally restrictive"
echo "   - Prevents known privilege escalations"
echo "   - Blocks: hostNetwork, hostPID, hostIPC, privileged, hostPath"
echo ""
echo "3. RESTRICTED (most secure)"
echo "   - Heavily restricted"
echo "   - Requires: runAsNonRoot, drop ALL capabilities, seccompProfile"
echo "   - Blocks: privileged, allowPrivilegeEscalation, etc."
echo ""
echo "PSA MODES:"
echo "  - enforce: Rejects pods that violate the policy"
echo "  - audit: Logs violations but allows pods"
echo "  - warn: Shows warnings but allows pods"
echo ""
echo "KEY POINTS:"
echo "  - --dry-run=server validates against the API server"
echo "  - This lets you preview policy violations before enforcing"
echo "  - Always keep compliant workloads running"
