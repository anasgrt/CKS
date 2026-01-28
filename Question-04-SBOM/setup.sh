#!/bin/bash
# Setup for Question 04 - SBOM with SPDX Format

set -e

echo "Setting up Question 04 - SBOM Generation..."

# Create output directory
mkdir -p /opt/course/04

# Check if bom tool is available
if command -v bom &> /dev/null; then
    echo "✓ bom tool is available"
elif command -v syft &> /dev/null; then
    echo "✓ syft tool is available (alternative)"
else
    echo "Note: Neither 'bom' nor 'syft' is installed."
    echo "In the real exam, these tools will be pre-installed."
    echo ""
    echo "To install bom:"
    echo "  go install sigs.k8s.io/bom/cmd/bom@latest"
    echo ""
    echo "To install syft:"
    echo "  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin"
fi

echo ""
echo "✓ Environment ready!"
echo ""
echo "Target image: nginx:1.25-alpine"
echo "Output file: /opt/course/04/sbom.spdx"
echo ""
echo "Commands to try:"
echo "  bom generate -o /opt/course/04/sbom.spdx --image nginx:1.25-alpine"
echo "  # OR using syft:"
echo "  syft nginx:1.25-alpine -o spdx > /opt/course/04/sbom.spdx"
