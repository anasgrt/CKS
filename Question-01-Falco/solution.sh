#!/bin/bash
# Solution for Question 01 - Falco Runtime Security Detection

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: Falco Runtime Security Detection"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Check Falco logs for suspicious activity"
echo "─────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Method 1: Using journalctl (systemd)
journalctl -u falco -f

# Method 2: Check Falco log file
sudo cat /var/log/falco/falco.log | grep -i "mem\|memory"

# Method 3: Tail Falco logs in real-time
sudo tail -f /var/log/falco/falco.log

# Look for alerts like:
# "Memory device /dev/mem opened"
# The alert will contain: pod=ollama-xxxxx ns=apps

# Example Falco output:
# 15:30:45.123456789: Warning Memory device /dev/mem opened
#   (user=root user_loginuid=-1 command=head -c 1 /hostdev/mem pid=12345
#    container_id=abc123 container_name=ollama pod=ollama-abc123 ns=apps)
EOF

echo ""
echo "STEP 2: Identify the problematic pod"
echo "─────────────────────────────────────"
echo ""
cat << 'EOF'
# List all pods in the apps namespace
kubectl get pods -n apps

# The Falco alert will show the pod name in the output
# In this case, look for 'ollama-xxxxx' in the Falco alerts

# Get the pod name
kubectl get pods -n apps -l app=ollama -o name
EOF

echo ""
echo "STEP 3: Scale down the offending deployment"
echo "────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Scale the ollama deployment to 0
kubectl scale deployment ollama -n apps --replicas=0

# Verify the scaling
kubectl get deployment ollama -n apps
EOF

echo ""
echo "STEP 4: Save your findings"
echo "──────────────────────────"
echo ""
cat << 'EOF'
# Create output directory
mkdir -p /opt/course/01

# Save the pod name
kubectl get pods -n apps -l app=ollama -o jsonpath='{.items[0].metadata.name}' > /opt/course/01/pod-name.txt

# Or if pod is already scaled down, you know it was:
echo "ollama-<pod-hash>" > /opt/course/01/pod-name.txt

# Save the Falco alert
# Copy the relevant line from Falco logs
echo "<timestamp> Notice Read sensitive device /dev/mem by container=ollama pod=ollama-xxxxx" > /opt/course/01/falco-alert.txt
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "QUICK COMMANDS TO EXECUTE:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Actually get the pod name for the solution
POD_NAME=$(kubectl get pods -n apps -l app=ollama -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "ollama-xxxxx")

echo "# 1. Check Falco logs for suspicious pod"
echo "sudo grep -i 'mem' /var/log/falco/falco.log | tail -5"
echo ""
echo "# 2. List pods to confirm"
echo "kubectl get pods -n apps"
echo ""
echo "# 3. Scale down the offending deployment (ollama)"
echo "kubectl scale deployment ollama -n apps --replicas=0"
echo ""
echo "# 4. Create output directory and save findings"
echo "mkdir -p /opt/course/01"
echo ""
echo "# 5. Save pod name (get it before scaling down!)"
echo "kubectl get pods -n apps -l app=ollama -o jsonpath='{.items[0].metadata.name}' > /opt/course/01/pod-name.txt"
echo ""
echo "# 6. Save Falco alert line"
echo "sudo grep -i 'ollama.*mem\|mem.*ollama' /var/log/falco/falco.log | tail -1 > /opt/course/01/falco-alert.txt"
echo ""
echo "KEY POINTS:"
echo "  - Falco detects runtime security threats via syscall monitoring"
echo "  - The 'ollama' deployment was accessing /dev/mem (memory device)"
echo "  - Look for pod name in Falco alerts: pod=ollama-xxxxx"
echo "  - Custom Falco rules are in /etc/falco/rules.d/"
echo "  - Always verify other deployments are still running"
echo ""
echo "FALCO LOG LOCATIONS:"
echo "  - Systemd: journalctl -u falco"
echo "  - File:    /var/log/falco/falco.log"
