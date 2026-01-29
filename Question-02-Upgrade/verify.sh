#!/bin/bash
# Verify Question 02 - Worker Node Kubernetes Upgrade

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Worker Node Upgrade..."
echo ""

# Check output files exist
echo "Checking output files..."

if [ -f "/opt/course/02/node-version-before.txt" ]; then
    echo -e "${GREEN}✓ node-version-before.txt exists${NC}"
    cat /opt/course/02/node-version-before.txt
else
    echo -e "${RED}✗ node-version-before.txt not found at /opt/course/02/node-version-before.txt${NC}"
    PASS=false
fi

if [ -f "/opt/course/02/node-version-after.txt" ]; then
    echo -e "${GREEN}✓ node-version-after.txt exists${NC}"
    cat /opt/course/02/node-version-after.txt
else
    echo -e "${RED}✗ node-version-after.txt not found at /opt/course/02/node-version-after.txt${NC}"
    PASS=false
fi

echo ""
echo "Checking node status..."

# Check if any node is schedulable (uncordoned)
NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
if [ "$NODES" -ge 1 ]; then
    echo -e "${GREEN}✓ Cluster has nodes${NC}"

    # Check if node is Ready
    READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c "Ready" || echo "0")
    if [ "$READY_NODES" -ge 1 ]; then
        echo -e "${GREEN}✓ Node(s) are in Ready state${NC}"
    else
        echo -e "${YELLOW}⚠ Check that nodes are in Ready state${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Cannot check nodes (single-node cluster or no access)${NC}"
fi

echo ""
echo "=============================================="
echo "Upgrade Process Checklist:"
echo "=============================================""
echo ""
echo "[ ] 1. Drain the node: kubectl drain node-01 --ignore-daemonsets --delete-emptydir-data"
echo "[ ] 2. SSH to node: ssh node-01"
echo "[ ] 3. Upgrade kubeadm: apt-get update && apt-get install -y kubeadm=1.34.1-*"
echo "[ ] 4. Apply upgrade: kubeadm upgrade node"
echo "[ ] 5. Upgrade kubelet/kubectl: apt-get install -y kubelet=1.34.1-* kubectl=1.34.1-*"
echo "[ ] 6. Restart kubelet: systemctl daemon-reload && systemctl restart kubelet"
echo "[ ] 7. Exit SSH: exit"
echo "[ ] 8. Uncordon: kubectl uncordon node-01"
echo ""

if $PASS; then
    echo -e "${GREEN}Output files verified!${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed.${NC}"
    exit 1
fi
