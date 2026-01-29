#!/bin/bash
# Setup for Question 06 - Docker Daemon Security Hardening

set -e

echo "Setting up Question 06 - Docker Daemon Hardening..."

# Create output directory
mkdir -p /opt/course/06

echo ""
echo "✓ Environment ready!"
echo ""
echo "This question simulates Docker daemon hardening."
echo "In the real exam, you would SSH to a node and perform these tasks:"
echo ""
echo "1. Remove user from docker group:"
echo "   sudo gpasswd -d developer docker"
echo ""
echo "2. Change socket ownership in /etc/docker/daemon.json:"
echo '   {"group": "root"}'
echo ""
echo "3. Remove TCP listeners from daemon.json"
echo ""
echo "4. Restart Docker:"
echo "   sudo systemctl restart docker"
echo ""
echo "Check Docker config:"
echo "  ls -la /var/run/docker.sock"
echo "  cat /etc/docker/daemon.json"
echo "  id developer"
echo ""
echo "NOTE: This cluster uses containerd, not Docker."
echo "      This question is for exam preparation only."
