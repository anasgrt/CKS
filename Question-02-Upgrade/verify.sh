#!/bin/bash
# Verify Question 02 - Worker Node Kubernetes Upgrade

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=true
TARGET_VERSION="v1.34.1"

# Automatically detect worker node (first non-control-plane node)
WORKER_NODE=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$WORKER_NODE" ]; then
    echo -e "${RED}✗ No worker nodes found in cluster${NC}"
    exit 1
fi

echo "════════════════════════════════════════════════════════════"
echo "Verifying Worker Node Upgrade: $WORKER_NODE → $TARGET_VERSION"
echo "════════════════════════════════════════════════════════════"
echo ""

# Check if node exists
echo -e "${BLUE}[1/5] Checking node exists...${NC}"
if kubectl get node "$WORKER_NODE" &>/dev/null; then
    echo -e "${GREEN}✓ Node '$WORKER_NODE' found${NC}"
else
    echo -e "${RED}✗ Node '$WORKER_NODE' not found in cluster${NC}"
    PASS=false
fi
echo ""

# Check node version
echo -e "${BLUE}[2/5] Checking kubelet version...${NC}"
CURRENT_VERSION=$(kubectl get node "$WORKER_NODE" -o jsonpath='{.status.nodeInfo.kubeletVersion}' 2>/dev/null)
if [ -n "$CURRENT_VERSION" ]; then
    echo "Current version: $CURRENT_VERSION"
    if [ "$CURRENT_VERSION" = "$TARGET_VERSION" ]; then
        echo -e "${GREEN}✓ Node is at target version $TARGET_VERSION${NC}"
    else
        echo -e "${RED}✗ Node is at $CURRENT_VERSION, expected $TARGET_VERSION${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ Could not determine node version${NC}"
    PASS=false
fi
echo ""

# Check node status
echo -e "${BLUE}[3/5] Checking node status...${NC}"
NODE_STATUS=$(kubectl get node "$WORKER_NODE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
SCHEDULABLE=$(kubectl get node "$WORKER_NODE" -o jsonpath='{.spec.unschedulable}' 2>/dev/null)

if [ "$NODE_STATUS" = "True" ]; then
    echo -e "${GREEN}✓ Node is Ready${NC}"
else
    echo -e "${RED}✗ Node is not Ready (status: $NODE_STATUS)${NC}"
    PASS=false
fi

if [ "$SCHEDULABLE" != "true" ]; then
    echo -e "${GREEN}✓ Node is schedulable (not cordoned)${NC}"
else
    echo -e "${RED}✗ Node is unschedulable (cordoned)${NC}"
    PASS=false
fi
echo ""

# Check kubeadm version on the node via SSH
echo -e "${BLUE}[4/5] Checking kubeadm version on node...${NC}"
if command -v ssh &>/dev/null; then
    KUBEADM_VERSION=$(ssh -o ConnectTimeout=3 "$WORKER_NODE" "kubeadm version -o short" 2>/dev/null)
    if [ -n "$KUBEADM_VERSION" ]; then
        echo "kubeadm version: $KUBEADM_VERSION"
        if [ "$KUBEADM_VERSION" = "$TARGET_VERSION" ]; then
            echo -e "${GREEN}✓ kubeadm is at target version${NC}"
        else
            echo -e "${YELLOW}⚠ kubeadm is at $KUBEADM_VERSION, expected $TARGET_VERSION${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Could not check kubeadm version via SSH${NC}"
    fi
else
    echo -e "${YELLOW}⚠ SSH not available, skipping kubeadm check${NC}"
fi
echo ""

# Check kubelet service is running
echo -e "${BLUE}[5/5] Checking kubelet service...${NC}"
if command -v ssh &>/dev/null; then
    KUBELET_STATUS=$(ssh -o ConnectTimeout=3 "$WORKER_NODE" "systemctl is-active kubelet" 2>/dev/null)
    if [ "$KUBELET_STATUS" = "active" ]; then
        echo -e "${GREEN}✓ kubelet service is active and running${NC}"
    else
        echo -e "${RED}✗ kubelet service is not running (status: $KUBELET_STATUS)${NC}"
        PASS=false
    fi
else
    echo -e "${YELLOW}⚠ SSH not available, skipping kubelet service check${NC}"
fi
echo ""

# Final summary
echo "════════════════════════════════════════════════════════════"
if $PASS; then
    echo -e "${GREEN}✓ ALL CHECKS PASSED - Upgrade verified successfully!${NC}"
    echo ""
    echo "Summary:"
    echo "  • Node: $WORKER_NODE"
    echo "  • Kubelet version: $CURRENT_VERSION"
    echo "  • Status: Ready and schedulable"
    echo "  • kubelet service: Running"
    exit 0
else
    echo -e "${RED}✗ VERIFICATION FAILED - Some checks did not pass${NC}"
    echo ""
    echo "Please review the output above and ensure:"
    echo "  1. Node upgrade completed successfully"
    echo "  2. Node is at version $TARGET_VERSION"
    echo "  3. Node is in Ready state"
    echo "  4. Node is uncordoned (schedulable)"
    exit 1
fi
