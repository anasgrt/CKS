#!/bin/bash
# Solution for Question 04 - SBOM Generation with bom and trivy

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: SBOM Generation, Trivy Scanning, Query, and Verification"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

IMAGE="nginx:1.25-alpine@sha256:721fa00bc549df26b3e67cc558ff176112d4ba69847537766f3c28e171d180e7"

echo "STEP 1: Create the output directory"
echo "────────────────────────────────────"
echo "mkdir -p /opt/course/04"
echo ""

echo "STEP 2: Generate SBOM using bom (SPDX format)"
echo "─────────────────────────────────────────────"
cat << 'EOF'
# Use the specific amd64 digest to avoid multiarch issues
bom generate -o /opt/course/04/sbom.spdx --image nginx:1.25-alpine@sha256:721fa00bc549df26b3e67cc558ff176112d4ba69847537766f3c28e171d180e7
EOF
echo ""

echo "STEP 3: Generate SBOM using trivy (SPDX-JSON format)"
echo "────────────────────────────────────────────────────"
cat << 'EOF'
# Use trivy to generate SBOM in SPDX-JSON format
trivy image --format spdx-json --output /opt/course/04/sbom.spdx.json nginx:1.25-alpine@sha256:721fa00bc549df26b3e67cc558ff176112d4ba69847537766f3c28e171d180e7
EOF
echo ""

echo "STEP 4: Scan the SBOM for vulnerabilities using trivy sbom"
echo "──────────────────────────────────────────────────────────"
cat << 'EOF'
# Use trivy to scan the generated SBOM for vulnerabilities
trivy sbom --format json /opt/course/04/sbom.spdx.json > /opt/course/04/sbom-vulns.json
EOF
echo ""

echo "STEP 5: Query the SBOM for SSL packages"
echo "───────────────────────────────────────"
cat << 'EOF'
# Use bom document query to find packages containing ssl or openssl
# ⚠️  NOTE: The --fields argument MUST be quoted: --fields 'name,version'
#     Without quotes, bash interprets it as two separate commands!
bom document query /opt/course/04/sbom.spdx 'name:ssl' --fields 'name,version' > /opt/course/04/ssl-packages.txt
bom document query /opt/course/04/sbom.spdx 'name:openssl' --fields 'name,version' >> /opt/course/04/ssl-packages.txt
EOF
echo ""

echo "STEP 6: Verify libcrypto3 package and get version"
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

# Generate SBOM with bom (SPDX format)
bom generate -o /opt/course/04/sbom.spdx --image nginx:1.25-alpine@sha256:721fa00bc549df26b3e67cc558ff176112d4ba69847537766f3c28e171d180e7

# Generate SBOM with trivy (SPDX-JSON format)
trivy image --format spdx-json --output /opt/course/04/sbom.spdx.json nginx:1.25-alpine@sha256:721fa00bc549df26b3e67cc558ff176112d4ba69847537766f3c28e171d180e7

# Scan SBOM for vulnerabilities
trivy sbom --format json /opt/course/04/sbom.spdx.json > /opt/course/04/sbom-vulns.json

# Query SSL packages (⚠️ ALWAYS quote --fields 'name,version')
bom document query /opt/course/04/sbom.spdx 'name:ssl' --fields 'name,version' > /opt/course/04/ssl-packages.txt
bom document query /opt/course/04/sbom.spdx 'name:openssl' --fields 'name,version' >> /opt/course/04/ssl-packages.txt

# Get libcrypto3 version
bom document query /opt/course/04/sbom.spdx 'name:libcrypto3' --fields 'name,version' > /opt/course/04/libcrypto-version.txt
EOF
echo ""

echo "═══════════════════════════════════════════════════════════════════"
echo "TRIVY SBOM COMMANDS:"
echo "═══════════════════════════════════════════════════════════════════"
cat << 'EOF'
# Generate SBOM in different formats:
trivy image --format spdx-json --output <path> <image>   # SPDX-JSON format
trivy image --format cyclonedx --output <path> <image>   # CycloneDX format
trivy image --format spdx --output <path> <image>        # SPDX tag-value format

# Scan an existing SBOM for vulnerabilities:
trivy sbom --format json <sbom-file>      # JSON output
trivy sbom --format table <sbom-file>     # Table output (human-readable)
trivy sbom <sbom-file>                    # Default table output

# Filter by severity:
trivy sbom --severity HIGH,CRITICAL <sbom-file>
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
echo "head -50 /opt/course/04/sbom-vulns.json"
echo ""

echo "KEY COMMANDS:"
echo "  bom generate -o <file> --image <image>           # Generate SBOM (SPDX)"
echo "  trivy image --format spdx-json --output <f> <i>  # Generate SBOM (SPDX-JSON)"
echo "  trivy sbom --format json <sbom>                  # Scan SBOM for vulns"
echo "  bom document outline <file>                      # View SBOM structure"
