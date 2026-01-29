#!/bin/bash
# Setup for Question 01 - Falco Runtime Security Detection

set -e

echo "Setting up Question 01 - Falco Runtime Security..."

# ============================================================
# Get list of worker nodes
# ============================================================
echo "Detecting cluster nodes..."
WORKER_NODES=$(kubectl get nodes --no-headers -o custom-columns=":metadata.name" | grep -v "cplane\|control\|master" || true)

if [ -z "$WORKER_NODES" ]; then
    echo "No worker nodes found, will install Falco on all nodes..."
    WORKER_NODES=$(kubectl get nodes --no-headers -o custom-columns=":metadata.name")
fi

echo "Worker nodes: $WORKER_NODES"

# ============================================================
# Install Falco as systemd service on each worker node
# ============================================================
install_falco_on_node() {
    local NODE=$1
    echo ""
    echo "Installing Falco on node: $NODE"
    echo "─────────────────────────────────────────"

    ssh -o StrictHostKeyChecking=no "$NODE" bash << 'REMOTE_SCRIPT'
        set -e

        # Check if Falco is already installed and running
        if systemctl is-active --quiet falco 2>/dev/null || systemctl is-active --quiet falco-modern-bpf 2>/dev/null; then
            echo "✓ Falco is already running on this node"
            exit 0
        fi

        echo "Installing Falco..."

        # Install prerequisites
        apt-get update -qq
        apt-get install -y -qq curl gnupg2 apt-transport-https ca-certificates

        # Add Falco repository
        if [ ! -f /usr/share/keyrings/falco-archive-keyring.gpg ]; then
            curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | \
                gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg
        fi

        if [ ! -f /etc/apt/sources.list.d/falcosecurity.list ]; then
            echo "deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main" | \
                tee /etc/apt/sources.list.d/falcosecurity.list
        fi

        apt-get update -qq

        # Install Falco with modern eBPF driver (no kernel headers needed)
        FALCO_FRONTEND=noninteractive apt-get install -y -qq falco

        # Configure Falco for container runtime
        mkdir -p /etc/falco/rules.d

        # Create custom rule for /dev/mem detection
        cat > /etc/falco/rules.d/dev_mem_access.yaml << 'FALCO_RULE'
# Custom rule to detect /dev/mem access
- rule: Memory device access detected
  desc: Detect read access to /dev/mem which can be used for memory dumping attacks
  condition: >
    evt.type in (open, openat, openat2) and
    evt.dir = < and
    fd.name startswith /dev/mem and
    container.id != host
  output: "Memory device /dev/mem opened (user=%user.name command=%proc.cmdline container_id=%container.id container_name=%container.name pod=%k8s.pod.name ns=%k8s.ns.name)"
  priority: WARNING
  tags: [container, memory, cks]
FALCO_RULE

        # Enable and start Falco service (try modern-bpf first, then regular)
        systemctl daemon-reload
        systemctl enable falco-modern-bpf.service 2>/dev/null || systemctl enable falco.service 2>/dev/null || true
        systemctl restart falco-modern-bpf.service 2>/dev/null || systemctl restart falco.service 2>/dev/null || true

        # Wait for service to start
        sleep 3

        # Verify Falco is running
        if systemctl is-active --quiet falco-modern-bpf 2>/dev/null || systemctl is-active --quiet falco 2>/dev/null; then
            echo "✓ Falco service started successfully"
        else
            echo "⚠ Falco service may not have started. Checking status..."
            systemctl status falco-modern-bpf --no-pager 2>/dev/null || systemctl status falco --no-pager 2>/dev/null || true
        fi
REMOTE_SCRIPT
}

# Install Falco on each worker node
for NODE in $WORKER_NODES; do
    install_falco_on_node "$NODE"
done

echo ""
echo "✓ Falco installation complete on all worker nodes"

# ============================================================
# Create Kubernetes Resources for the Question
# ============================================================
echo ""
echo "Creating Kubernetes resources..."

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

# Give Falco time to detect the activity
sleep 5

echo ""
echo "✓ Environment ready!"
echo ""
echo "Namespace: apps"
echo "Deployments: nvidia-gpu, cpu, ollama"
echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "HOW TO VIEW FALCO LOGS:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "1. Find which node the suspicious pod is running on:"
echo "   kubectl get pods -n apps -o wide"
echo ""
echo "2. SSH to that node and check Falco logs with journalctl:"
echo "   ssh <node-name> journalctl -u falco -f"
echo "   ssh <node-name> journalctl -u falco | grep -i mem"
echo ""
echo "Example:"
echo "   ssh node-02 journalctl -u falco --no-pager | grep -i mem"
echo ""
