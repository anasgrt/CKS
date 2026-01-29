#!/bin/bash
# Setup for Question 01 - Falco Runtime Security Detection

set -e

echo "Setting up Question 01 - Falco Runtime Security..."

# ============================================================
# PREREQUISITE: Ensure Falco is installed and running
# ============================================================
echo "Checking Falco installation..."

if ! command -v falco &> /dev/null && ! systemctl list-unit-files | grep -q falco; then
    echo "⚠️  Falco is not installed. Installing Falco..."

    # Add Falco repository and install
    curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | \
        sudo gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg

    echo "deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main" | \
        sudo tee /etc/apt/sources.list.d/falcosecurity.list

    sudo apt-get update -y
    sudo apt-get install -y falco

    echo "✓ Falco installed successfully"
fi

# Ensure Falco service is running
if systemctl is-active --quiet falco 2>/dev/null; then
    echo "✓ Falco service is already running"
else
    echo "Starting Falco service..."
    sudo systemctl enable falco 2>/dev/null || true
    sudo systemctl start falco 2>/dev/null || true

    # If systemd fails, try running falco directly in background
    if ! systemctl is-active --quiet falco 2>/dev/null; then
        echo "Starting Falco manually..."
        sudo mkdir -p /var/log/falco
        sudo nohup falco -o "file_output.enabled=true" \
                         -o "file_output.filename=/var/log/falco/falco.log" \
                         > /dev/null 2>&1 &
        sleep 3
    fi
fi

# Create custom Falco rule for /dev/mem detection
echo "Configuring Falco rules for memory device detection..."
sudo mkdir -p /etc/falco/rules.d

cat << 'FALCO_RULE' | sudo tee /etc/falco/rules.d/dev_mem_access.yaml > /dev/null
# Custom rule to detect /dev/mem access
# Falco sees the actual host path even when accessed via container mount
- rule: Memory device access detected
  desc: Detect read access to /dev/mem which can be used for memory dumping attacks
  condition: >
    evt.type in (open, openat, openat2) and
    evt.dir = < and
    (fd.name = "/dev/mem" or fd.name contains "/mem") and
    container.id != host
  output: >
    Memory device /dev/mem opened (user=%user.name user_loginuid=%user.loginuid command=%proc.cmdline pid=%proc.pid container_id=%container.id container_name=%container.name pod=%k8s.pod.name ns=%k8s.ns.name)
  priority: WARNING
  tags: [host, container, memory, cks]
FALCO_RULE

# Restart Falco to load new rules
echo "Restarting Falco to apply new rules..."
sudo systemctl restart falco 2>/dev/null || \
    (sudo pkill falco 2>/dev/null; sleep 2; \
     sudo nohup falco -o "file_output.enabled=true" \
                      -o "file_output.filename=/var/log/falco/falco.log" \
                      > /dev/null 2>&1 &)
sleep 3

# Verify Falco is running
if pgrep -x falco > /dev/null || systemctl is-active --quiet falco 2>/dev/null; then
    echo "✓ Falco is running and configured"
else
    echo "⚠️  Warning: Falco may not be running. Check manually."
fi

# ============================================================
# Create Kubernetes Resources
# ============================================================

# Create namespace
kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f -

# Create nvidia-gpu deployment (harmless)
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nvidia-gpu
  namespace: apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nvidia-gpu
  template:
    metadata:
      labels:
        app: nvidia-gpu
    spec:
      containers:
      - name: nvidia-gpu
        image: busybox:1.36
        command: ["sh", "-c", "while true; do echo 'GPU processing...'; sleep 30; done"]
EOF

# Create cpu deployment (harmless)
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu
  namespace: apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cpu
  template:
    metadata:
      labels:
        app: cpu
    spec:
      containers:
      - name: cpu
        image: busybox:1.36
        command: ["sh", "-c", "while true; do echo 'CPU processing...'; sleep 30; done"]
EOF

# Create ollama deployment (the malicious one - accessing /dev/mem)
# Uses hostPID and mounts host /dev to ensure /dev/mem is accessible
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ollama
  namespace: apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ollama
  template:
    metadata:
      labels:
        app: ollama
    spec:
      hostPID: true
      containers:
      - name: ollama
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          while true; do
            # Attempt to read /dev/mem - this will trigger Falco
            if [ -e /dev/mem ]; then
              head -c 1 /dev/mem 2>/dev/null || true
            fi
            # Also try via hostdev mount
            if [ -e /hostdev/mem ]; then
              head -c 1 /hostdev/mem 2>/dev/null || true
            fi
            echo "Memory access attempt at $(date)"
            sleep 15
          done
        securityContext:
          privileged: true
        volumeMounts:
        - name: hostdev
          mountPath: /hostdev
          readOnly: true
      volumes:
      - name: hostdev
        hostPath:
          path: /dev
          type: Directory
EOF

# Create output directory
mkdir -p /opt/course/01

# Wait for pods to be ready
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=nvidia-gpu -n apps --timeout=60s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app=cpu -n apps --timeout=60s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app=ollama -n apps --timeout=60s 2>/dev/null || true

echo ""
echo "✓ Environment ready!"
echo ""
echo "Namespace: apps"
echo "Deployments: nvidia-gpu, cpu, ollama"
echo ""
echo "Check deployments with: kubectl get deployments -n apps"
echo "Check Falco logs with: journalctl -u falco -f"
echo "                   or: sudo cat /var/log/falco/falco.log"
