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
# Use the specific amd64 digest to avoid multiarch issues
bom generate -o /opt/course/04/sbom.spdx --image nginx:1.25-alpine@sha256:721fa00bc549df26b3e67cc558ff176112d4ba69847537766f3c28e171d180e7
EOF
echo ""

echo "STEP 3: Query the SBOM for SSL packages"
echo "───────────────────────────────────────"
cat << 'EOF'
# Use bom document query to find packages containing ssl or openssl
# ⚠️  NOTE: The --fields argument MUST be quoted: --fields 'name,version'
#     Without quotes, bash interprets it as two separate commands!
bom document query /opt/course/04/sbom.spdx 'name:ssl' --fields 'name,version' > /opt/course/04/ssl-packages.txt
bom document query /opt/course/04/sbom.spdx 'name:openssl' --fields 'name,version' >> /opt/course/04/ssl-packages.txt
EOF
echo ""

echo "STEP 4: Verify libcrypto3 package and get version"
echo "─────────────────────────────────────────────────"
cat << 'EOF'
# Query for libcrypto3 package
bom document query /opt/course/04/sbom.spdx 'name:libcrypto3' --fields 'name,version' > /opt/course/04/libcrypto-version.txt
EOF
echo ""

echo "═══════════════════════════════════════════════════════════════════"
echo "QUICK SOLUTION (Copy-Paste Ready):"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
cat << 'EOF'
mkdir -p /opt/course/04
bom generate -o /opt/course/04/sbom.spdx --image nginx:1.25-alpine@sha256:721fa00bc549df26b3e67cc558ff176112d4ba69847537766f3c28e171d180e7
# ⚠️  IMPORTANT: Always quote --fields 'name,version' to avoid bash parsing errors!
bom document query /opt/course/04/sbom.spdx 'name:ssl' --fields 'name,version' > /opt/course/04/ssl-packages.txt
bom document query /opt/course/04/sbom.spdx 'name:openssl' --fields 'name,version' >> /opt/course/04/ssl-packages.txt
bom document query /opt/course/04/sbom.spdx 'name:libcrypto3' --fields 'name,version' > /opt/course/04/libcrypto-version.txt
EOF
echo ""

echo "═══════════════════════════════════════════════════════════════════"
echo "BOM DOCUMENT COMMANDS:"
echo "═══════════════════════════════════════════════════════════════════"
cat << 'EOF'
# View SBOM structure/outline:
bom document outline /opt/course/04/sbom.spdx

# Query packages by name (⚠️ ALWAYS quote the --fields argument!):
bom document query /opt/course/04/sbom.spdx 'name:packagename' --fields 'name,version'

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
