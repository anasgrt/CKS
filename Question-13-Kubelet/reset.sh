#!/bin/bash
# Reset Question 13 - Kubelet Security Configuration

rm -rf /opt/course/13

# Detect worker node
WORKER_NODE=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$WORKER_NODE" ]; then
    echo "Restoring secure kubelet settings on $WORKER_NODE..."

    ssh "$WORKER_NODE" << 'REMOTE_SCRIPT'
# Restore from backup if it exists
if [ -f /var/lib/kubelet/config.yaml.bak ]; then
    sudo cp /var/lib/kubelet/config.yaml.bak /var/lib/kubelet/config.yaml
    sudo rm /var/lib/kubelet/config.yaml.bak
fi

# Ensure secure settings (in case backup doesn't exist)
# 1. Disable anonymous authentication
sudo sed -i '/anonymous:/,/enabled:/{s/enabled: true/enabled: false/}' /var/lib/kubelet/config.yaml

# 2. Enable webhook authentication
sudo sed -i '/webhook:/,/enabled:/{s/enabled: false/enabled: true/}' /var/lib/kubelet/config.yaml

# 3. Set authorization mode to Webhook
sudo sed -i 's/mode: AlwaysAllow/mode: Webhook/' /var/lib/kubelet/config.yaml

# Restart kubelet
sudo systemctl restart kubelet
REMOTE_SCRIPT

    echo "Waiting for kubelet to restart..."
    sleep 5
fi

echo ""
echo "Question 13 reset complete!"
