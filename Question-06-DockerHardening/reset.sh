#!/bin/bash
# Reset Question 06 - Docker Daemon Security Hardening

rm -rf /opt/course/06

echo "Question 06 reset complete!"
echo ""
echo "⚠️  MANUAL CLEANUP REQUIRED (if you made changes on the node):"
echo "   SSH to the node and:"
echo "   1. Add user back to docker group: sudo gpasswd -a developer docker"
echo "   2. Restore Docker daemon.json to original state"
echo "   3. Restart Docker: sudo systemctl restart docker"
