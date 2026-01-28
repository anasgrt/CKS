#!/bin/bash
# Solution for Question 04 - SBOM with SPDX Format
# Based on CKS 2024/2025 Supply Chain Security curriculum

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: SBOM (Software Bill of Materials) Generation"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "STEP 0: Create the output directory"
echo "────────────────────────────────────"
echo "mkdir -p /opt/course/04"
echo ""

echo "STEP 1: Check which SBOM tool is available"
echo "──────────────────────────────────────────"
echo "which bom syft trivy"
echo ""

echo "═══════════════════════════════════════════════════════════════════"
echo "OPTION 1: Using 'bom' tool (Kubernetes SIG Release)"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
cat << 'EOF'
# bom is the official Kubernetes SBOM tool
# GitHub: https://github.com/kubernetes-sigs/bom

# Basic command to generate SBOM in SPDX format (default):
bom generate -o /opt/course/04/sbom.spdx --image nginx:1.25-alpine

# With verbose output:
bom generate -o /opt/course/04/sbom.spdx --image nginx:1.25-alpine --log-level debug

# Generate in JSON format:
bom generate -o /opt/course/04/sbom.json --format json --image nginx:1.25-alpine

# Analyze image with deeper inspection:
bom generate -a -o /opt/course/04/sbom.spdx --image nginx:1.25-alpine
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "OPTION 2: Using 'syft' tool (Anchore)"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
cat << 'EOF'
# syft is a popular SBOM generator from Anchore
# GitHub: https://github.com/anchore/syft

# Generate SBOM in SPDX tag-value format:
syft nginx:1.25-alpine -o spdx > /opt/course/04/sbom.spdx

# Generate SBOM in SPDX JSON format:
syft nginx:1.25-alpine -o spdx-json > /opt/course/04/sbom.spdx.json

# Generate SBOM in CycloneDX format:
syft nginx:1.25-alpine -o cyclonedx > /opt/course/04/sbom.cdx

# Generate SBOM in CycloneDX JSON format:
syft nginx:1.25-alpine -o cyclonedx-json > /opt/course/04/sbom.cdx.json

# List available output formats:
syft --help | grep -A20 "Available formats"
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "OPTION 3: Using 'trivy' tool (Aqua Security)"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
cat << 'EOF'
# trivy is primarily a vulnerability scanner but can generate SBOMs
# Documentation available during exam: https://github.com/aquasecurity/trivy

# Generate SBOM in SPDX format:
trivy image --format spdx nginx:1.25-alpine > /opt/course/04/sbom.spdx

# Generate SBOM in SPDX JSON format:
trivy image --format spdx-json nginx:1.25-alpine > /opt/course/04/sbom.spdx.json

# Generate SBOM in CycloneDX format:
trivy image --format cyclonedx nginx:1.25-alpine > /opt/course/04/sbom.cdx

# Note: trivy also does vulnerability scanning, which may be asked separately
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "QUICK SOLUTION (Copy-Paste Ready):"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "mkdir -p /opt/course/04"
echo ""
echo "# Using bom (preferred if available):"
echo "bom generate -o /opt/course/04/sbom.spdx --image nginx:1.25-alpine"
echo ""
echo "# Using syft:"
echo "syft nginx:1.25-alpine -o spdx > /opt/course/04/sbom.spdx"
echo ""
echo "# Using trivy:"
echo "trivy image --format spdx nginx:1.25-alpine > /opt/course/04/sbom.spdx"
echo ""

echo "═══════════════════════════════════════════════════════════════════"
echo "VERIFY YOUR SOLUTION:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "# Check file exists and has content:"
echo "ls -la /opt/course/04/sbom.spdx"
echo "wc -l /opt/course/04/sbom.spdx"
echo ""
echo "# Verify SPDX format (look for SPDX headers):"
echo "head -20 /opt/course/04/sbom.spdx"
echo ""
echo "# Look for nginx package references:"
echo "grep -i nginx /opt/course/04/sbom.spdx | head -5"
echo ""

echo "═══════════════════════════════════════════════════════════════════"
echo "KEY CONCEPTS TO REMEMBER:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "WHAT IS AN SBOM?"
echo "  - Software Bill of Materials"
echo "  - Lists ALL packages, libraries, and dependencies in software"
echo "  - Critical for supply chain security"
echo "  - Helps identify vulnerabilities in dependencies"
echo ""
echo "SBOM FORMATS:"
echo "  - SPDX (Software Package Data Exchange) - Linux Foundation standard"
echo "  - CycloneDX - OWASP standard"
echo ""
echo "WHY SBOM MATTERS FOR CKS:"
echo "  - Part of 'Supply Chain Security' domain (20% of exam)"
echo "  - Executive Order 14028 requires SBOMs for government software"
echo "  - Helps with vulnerability management and compliance"
echo ""
echo "ALLOWED DOCUMENTATION DURING EXAM:"
echo "  - https://github.com/aquasecurity/trivy (Trivy docs)"
echo "  - https://github.com/kubernetes-sigs/bom (bom docs)"
echo "  - https://github.com/anchore/syft (syft docs)"
