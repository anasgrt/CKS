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
# Falco runs as a systemd service on each worker node

# First, find which node the apps pods are running on:
kubectl get pods -n apps -o wide

# SSH to that node and check Falco logs with journalctl:
ssh <node-name> journalctl -u falco --no-pager | grep -i mem

# Or follow logs in real-time:
ssh <node-name> journalctl -u falco -f

# Example commands:
ssh node-02 journalctl -u falco --no-pager | grep -i mem
ssh node-02 journalctl -u falco -f

# Look for alerts like:
# "Memory device /dev/mem opened"
# The alert will contain: pod=ollama-xxxxx ns=apps

# Example Falco output:
# Jan 29 15:30:45 node-02 falco: Warning Memory device /dev/mem opened
#   (user=root command=head -c 1 /hostdev/mem container_id=abc123
#    container_name=ollama pod=ollama-abc123 ns=apps)
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

echo "# 1. Find which node pods are running on"
echo "kubectl get pods -n apps -o wide"
echo ""
echo "# 2. Check Falco logs on that node (e.g., node-02)"
echo "ssh node-02 journalctl -u falco --no-pager | grep -i mem"
echo ""
echo "# 3. Scale down the offending deployment (ollama)"
echo "kubectl scale deployment ollama -n apps --replicas=0"
echo ""
echo "# 4. Create output directory and save findings"
echo "mkdir -p /opt/course/01"
echo ""
echo "# 5. Save pod name (get it BEFORE scaling down!)"
echo "kubectl get pods -n apps -l app=ollama -o jsonpath='{.items[0].metadata.name}' > /opt/course/01/pod-name.txt"
echo ""
echo "# 6. Save Falco alert line"
echo "ssh node-02 journalctl -u falco --no-pager | grep -i 'ollama.*mem' | tail -1 > /opt/course/01/falco-alert.txt"
echo ""
echo "KEY POINTS:"
echo "  - Falco runs as a systemd service on each worker node"
echo "  - Falco detects runtime security threats via syscall monitoring"
echo "  - The 'ollama' deployment was accessing /dev/mem (memory device)"
echo "  - Look for pod name in Falco alerts: pod=ollama-xxxxx"
echo "  - Always verify other deployments are still running"
echo ""
echo "FALCO LOG LOCATIONS (systemd service):"
echo "  - journalctl -u falco"
echo "  - journalctl -u falco-modern-bpf"
