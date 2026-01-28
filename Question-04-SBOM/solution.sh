#!/bin/bash
# Solution for Question 04 - SBOM with SPDX Format

echo "═══════════════════════════════════════════════════════════════════"
echo "Solution: SBOM with SPDX Format"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "OPTION 1: Using 'bom' tool (Kubernetes SIG Release)"
echo "────────────────────────────────────────────────────"
echo ""
cat << 'EOF'
# Generate SBOM using bom
bom generate -o /opt/course/04/sbom.spdx --image nginx:1.25-alpine

# Alternative format options:
bom generate -o /opt/course/04/sbom.json --format json --image nginx:1.25-alpine
EOF

echo ""
echo "OPTION 2: Using 'syft' tool (Anchore)"
echo "─────────────────────────────────────"
echo ""
cat << 'EOF'
# Generate SBOM using syft in SPDX format
syft nginx:1.25-alpine -o spdx > /opt/course/04/sbom.spdx

# Other syft output formats:
syft nginx:1.25-alpine -o spdx-json > /opt/course/04/sbom.spdx.json
syft nginx:1.25-alpine -o cyclonedx > /opt/course/04/sbom.cdx
EOF

echo ""
echo "OPTION 3: Using 'trivy' tool"
echo "────────────────────────────"
echo ""
cat << 'EOF'
# Generate SBOM using trivy
trivy image --format spdx nginx:1.25-alpine > /opt/course/04/sbom.spdx

# Or with JSON output
trivy image --format spdx-json nginx:1.25-alpine > /opt/course/04/sbom.spdx.json
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "QUICK COMMAND:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "mkdir -p /opt/course/04"
echo "bom generate -o /opt/course/04/sbom.spdx --image nginx:1.25-alpine"
echo ""
echo "# OR"
echo "syft nginx:1.25-alpine -o spdx > /opt/course/04/sbom.spdx"
echo ""

echo "KEY POINTS:"
echo "  - SBOM = Software Bill of Materials"
echo "  - SPDX is a standard SBOM format (from Linux Foundation)"
echo "  - SBOMs list all packages/dependencies in an image"
echo "  - Important for supply chain security and vulnerability tracking"
echo ""
echo "SBOM Formats:"
echo "  - SPDX (Software Package Data Exchange)"
echo "  - CycloneDX"
echo "  - Syft JSON"
