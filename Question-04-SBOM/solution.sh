#!/bin/bash
# Solution for Question 04 - SBOM Generation, Query, and Verification

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: SBOM Generation, Query, and Package Verification"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Create the output directory"
echo "────────────────────────────────────"
echo "mkdir -p /opt/course/04"
echo ""

echo "STEP 2: Generate SBOM using bom"
echo "───────────────────────────────"
cat << 'EOF'
bom generate -o /opt/course/04/sbom.spdx --image nginx:1.25-alpine
EOF
echo ""

echo "STEP 3: Query the SBOM for SSL packages"
echo "───────────────────────────────────────"
cat << 'EOF'
# Option A: Use grep directly on the SBOM file
grep -i "ssl\|openssl" /opt/course/04/sbom.spdx > /opt/course/04/ssl-packages.txt

# Option B: Use bom document outline and grep
bom document outline /opt/course/04/sbom.spdx | grep -i ssl > /opt/course/04/ssl-packages.txt
EOF
echo ""

echo "STEP 4: Verify libcrypto3 package and get version"
echo "─────────────────────────────────────────────────"
cat << 'EOF'
# Search for libcrypto3 and extract version
grep -i "libcrypto3" /opt/course/04/sbom.spdx | grep -oP 'libcrypto3[@-]\K[0-9.]+' > /opt/course/04/libcrypto-version.txt

# Or using awk to extract version:
grep -i "libcrypto3" /opt/course/04/sbom.spdx | head -1 | awk -F'@' '{print $2}' > /opt/course/04/libcrypto-version.txt

# Or simply grep and manually identify version:
grep -i "libcrypto3" /opt/course/04/sbom.spdx > /opt/course/04/libcrypto-version.txt
EOF
echo ""

echo "═══════════════════════════════════════════════════════════════════"
echo "QUICK SOLUTION (Copy-Paste Ready):"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
cat << 'EOF'
mkdir -p /opt/course/04
bom generate -o /opt/course/04/sbom.spdx --image nginx:1.25-alpine
grep -i "ssl\|openssl" /opt/course/04/sbom.spdx > /opt/course/04/ssl-packages.txt
grep -i "libcrypto3" /opt/course/04/sbom.spdx > /opt/course/04/libcrypto-version.txt
EOF
echo ""

echo "═══════════════════════════════════════════════════════════════════"
echo "BOM DOCUMENT COMMANDS:"
echo "═══════════════════════════════════════════════════════════════════"
cat << 'EOF'
# View SBOM structure/outline:
bom document outline /opt/course/04/sbom.spdx

# The outline shows packages in a tree format like:
#  📦 DESCRIBES 1 Packages
#  ├ sha256:...
#  │  ├ CONTAINS PACKAGE libcrypto3@3.0.12
#  │  ├ CONTAINS PACKAGE libssl3@3.0.12
#  │  ├ CONTAINS PACKAGE openssl@3.0.12
EOF
echo ""

echo "═══════════════════════════════════════════════════════════════════"
echo "VERIFY YOUR SOLUTION:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "ls -la /opt/course/04/"
echo "cat /opt/course/04/ssl-packages.txt"
echo "cat /opt/course/04/libcrypto-version.txt"
echo ""

echo "KEY BOM COMMANDS:"
echo "  bom generate -o <file> --image <image>  # Generate SBOM"
echo "  bom document outline <file>             # View SBOM structure"
