#!/bin/bash
# Verify Question 04 - SBOM Generation with bom and trivy

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking SBOM Generation, Trivy Scanning, Query, and Package Verification..."
echo ""

# Part 1: Check if bom SBOM file exists
echo "Part 1: SBOM Generation (bom - SPDX format)"
echo "───────────────────────────────────────────"
if [ -f "/opt/course/04/sbom.spdx" ]; then
    echo -e "${GREEN}✓ sbom.spdx file exists${NC}"

    if [ -s "/opt/course/04/sbom.spdx" ]; then
        echo -e "${GREEN}✓ sbom.spdx is not empty${NC}"
    else
        echo -e "${RED}✗ sbom.spdx is empty${NC}"
        PASS=false
    fi

    if grep -qi "SPDX\|SPDXRef\|spdxVersion" /opt/course/04/sbom.spdx 2>/dev/null; then
        echo -e "${GREEN}✓ File appears to be in SPDX format${NC}"
    else
        echo -e "${YELLOW}⚠ Could not verify SPDX format${NC}"
    fi

    if grep -qi "nginx" /opt/course/04/sbom.spdx 2>/dev/null; then
        echo -e "${GREEN}✓ SBOM contains nginx references${NC}"
    else
        echo -e "${YELLOW}⚠ Could not find nginx references in SBOM${NC}"
    fi
else
    echo -e "${RED}✗ sbom.spdx not found at /opt/course/04/sbom.spdx${NC}"
    PASS=false
fi

echo ""

# Part 2: Check if trivy SBOM file exists (SPDX-JSON)
echo "Part 2: SBOM Generation (trivy - SPDX-JSON format)"
echo "──────────────────────────────────────────────────"
if [ -f "/opt/course/04/sbom.spdx.json" ]; then
    echo -e "${GREEN}✓ sbom.spdx.json file exists${NC}"

    if [ -s "/opt/course/04/sbom.spdx.json" ]; then
        echo -e "${GREEN}✓ sbom.spdx.json is not empty${NC}"
    else
        echo -e "${RED}✗ sbom.spdx.json is empty${NC}"
        PASS=false
    fi

    if grep -qi "spdxVersion\|SPDX" /opt/course/04/sbom.spdx.json 2>/dev/null; then
        echo -e "${GREEN}✓ File appears to be in SPDX-JSON format${NC}"
    else
        echo -e "${YELLOW}⚠ Could not verify SPDX-JSON format${NC}"
    fi

    if grep -qi "nginx" /opt/course/04/sbom.spdx.json 2>/dev/null; then
        echo -e "${GREEN}✓ SBOM contains nginx references${NC}"
    else
        echo -e "${YELLOW}⚠ Could not find nginx references in SBOM${NC}"
    fi
else
    echo -e "${RED}✗ sbom.spdx.json not found at /opt/course/04/sbom.spdx.json${NC}"
    PASS=false
fi

echo ""

# Part 3: Check if trivy sbom scan results exist
echo "Part 3: SBOM Vulnerability Scan (trivy sbom)"
echo "────────────────────────────────────────────"
if [ -f "/opt/course/04/sbom-vulns.json" ]; then
    echo -e "${GREEN}✓ sbom-vulns.json file exists${NC}"

    if [ -s "/opt/course/04/sbom-vulns.json" ]; then
        echo -e "${GREEN}✓ sbom-vulns.json is not empty${NC}"
    else
        echo -e "${RED}✗ sbom-vulns.json is empty${NC}"
        PASS=false
    fi

    if grep -qi "Results\|Vulnerabilities\|SchemaVersion" /opt/course/04/sbom-vulns.json 2>/dev/null; then
        echo -e "${GREEN}✓ File appears to be a valid trivy scan result${NC}"
    else
        echo -e "${YELLOW}⚠ Could not verify trivy scan format${NC}"
    fi
else
    echo -e "${RED}✗ sbom-vulns.json not found at /opt/course/04/sbom-vulns.json${NC}"
    PASS=false
fi

echo ""

# Part 4: Check if SSL packages file exists
echo "Part 4: SSL Packages Query"
echo "──────────────────────────"
if [ -f "/opt/course/04/ssl-packages.txt" ]; then
    echo -e "${GREEN}✓ ssl-packages.txt file exists${NC}"

    if [ -s "/opt/course/04/ssl-packages.txt" ]; then
        echo -e "${GREEN}✓ ssl-packages.txt is not empty${NC}"

        if grep -qi "ssl\|openssl" /opt/course/04/ssl-packages.txt 2>/dev/null; then
            echo -e "${GREEN}✓ File contains SSL/OpenSSL references${NC}"
        else
            echo -e "${YELLOW}⚠ File doesn't contain expected SSL references${NC}"
        fi
    else
        echo -e "${RED}✗ ssl-packages.txt is empty${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ ssl-packages.txt not found at /opt/course/04/ssl-packages.txt${NC}"
    PASS=false
fi

echo ""

# Part 5: Check if libcrypto version file exists
echo "Part 5: Package Version Verification"
echo "────────────────────────────────────"
if [ -f "/opt/course/04/libcrypto-version.txt" ]; then
    echo -e "${GREEN}✓ libcrypto-version.txt file exists${NC}"

    if [ -s "/opt/course/04/libcrypto-version.txt" ]; then
        echo -e "${GREEN}✓ libcrypto-version.txt is not empty${NC}"

        if grep -qi "libcrypto\|crypto" /opt/course/04/libcrypto-version.txt 2>/dev/null; then
            echo -e "${GREEN}✓ File contains libcrypto references${NC}"
        else
            echo -e "${YELLOW}⚠ File may contain only version number (acceptable)${NC}"
        fi

        echo -e "  Content: $(cat /opt/course/04/libcrypto-version.txt | head -1)"
    else
        echo -e "${RED}✗ libcrypto-version.txt is empty${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ libcrypto-version.txt not found at /opt/course/04/libcrypto-version.txt${NC}"
    PASS=false
fi

echo ""
echo "=============================================="
echo "Summary"
echo "=============================================="

if $PASS; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed.${NC}"
    exit 1
fi

