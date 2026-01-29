#!/bin/bash
# Setup for Question 04 - SBOM with SPDX Format

set -e

echo "Setting up Question 04 - SBOM Generation..."

# Create output directory
mkdir -p /opt/course/04

# Install bom tool if not available
install_bom() {
    echo "Installing bom tool..."

    # Get latest version from GitHub
    BOM_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/bom/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

    # Fallback version if API fails
    if [ -z "$BOM_VERSION" ]; then
        BOM_VERSION="v0.6.0"
    fi

    echo "Downloading bom ${BOM_VERSION}..."

    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
    esac

    # Download and install
    curl -sSfL "https://github.com/kubernetes-sigs/bom/releases/download/${BOM_VERSION}/bom-linux-${ARCH}" -o /usr/local/bin/bom
    chmod +x /usr/local/bin/bom

    echo "✓ bom installed successfully"
}

# Check if bom tool is available, install if not
if command -v bom &> /dev/null; then
    echo "✓ bom tool is already available"
else
    install_bom
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
