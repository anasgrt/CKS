#!/bin/bash
# Setup for Question 04 - SBOM with SPDX Format (bom + trivy)

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

    # Download and install (bom uses format: bom-amd64-linux)
    curl -sSfL "https://github.com/kubernetes-sigs/bom/releases/download/${BOM_VERSION}/bom-${ARCH}-linux" -o /usr/local/bin/bom
    chmod +x /usr/local/bin/bom

    echo "✓ bom installed successfully"
}

# Install trivy if not available
install_trivy() {
    echo "Installing trivy..."

    # Install trivy using official installer script
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

    echo "✓ trivy installed successfully"
}

# Check if bom tool is available, install if not
if command -v bom &> /dev/null; then
    echo "✓ bom tool is already available"
else
    install_bom
fi

# Check if trivy is available, install if not
if command -v trivy &> /dev/null; then
    echo "✓ trivy is already available"
else
    install_trivy
fi

echo ""
echo "✓ Environment ready!"
echo ""
echo "Target image: nginx:1.25-alpine@sha256:721fa00bc549df26b3e67cc558ff176112d4ba69847537766f3c28e171d180e7"
echo ""
echo "Output files:"
echo "  - /opt/course/04/sbom.spdx        (bom - SPDX format)"
echo "  - /opt/course/04/sbom.spdx.json   (trivy - SPDX-JSON format)"
echo "  - /opt/course/04/sbom-vulns.json  (trivy sbom scan results)"
echo "  - /opt/course/04/ssl-packages.txt"
echo "  - /opt/course/04/libcrypto-version.txt"
echo ""
echo "Commands to try:"
echo "  bom generate -o /opt/course/04/sbom.spdx --image nginx:1.25-alpine@sha256:721fa00bc549df26b3e67cc558ff176112d4ba69847537766f3c28e171d180e7"
