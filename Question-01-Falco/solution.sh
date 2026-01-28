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

# Method 3: Using crictl to check container logs
sudo crictl logs <container-id>

# Look for alerts like:
# "Read sensitive file untrusted"
# "Write below etc"
# Or any alert mentioning /dev/mem
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
echo "# 1. Find the bad pod (check Falco first, then verify)"
echo "kubectl get pods -n apps"
echo ""
echo "# 2. Scale down ollama"
echo "kubectl scale deployment ollama -n apps --replicas=0"
echo ""
echo "# 3. Save findings"
echo "mkdir -p /opt/course/01"
echo "echo 'ollama' > /opt/course/01/pod-name.txt"
echo "echo 'Falco alert: pod ollama accessing /dev/mem' > /opt/course/01/falco-alert.txt"
echo ""
echo "KEY POINTS:"
echo "  - Falco detects runtime security threats"
echo "  - Look for suspicious activity in Falco logs"
echo "  - The 'ollama' deployment was accessing /dev/mem"
echo "  - Always verify other deployments are still running"
