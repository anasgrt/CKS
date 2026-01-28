#!/bin/bash
# Verify Question 04 - SBOM with SPDX Format

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking SBOM Generation..."
echo ""

# Check if output file exists
if [ -f "/opt/course/04/sbom.spdx" ]; then
    echo -e "${GREEN}✓ sbom.spdx file exists${NC}"

    # Check file is not empty
    if [ -s "/opt/course/04/sbom.spdx" ]; then
        echo -e "${GREEN}✓ sbom.spdx is not empty${NC}"
    else
        echo -e "${RED}✗ sbom.spdx is empty${NC}"
        PASS=false
    fi

    # Check for SPDX format indicators
    if grep -qi "SPDX\|SPDXRef\|spdxVersion" /opt/course/04/sbom.spdx 2>/dev/null; then
        echo -e "${GREEN}✓ File appears to be in SPDX format${NC}"
    else
        echo -e "${YELLOW}⚠ Could not verify SPDX format (file might still be valid)${NC}"
    fi

    # Check for nginx reference
    if grep -qi "nginx" /opt/course/04/sbom.spdx 2>/dev/null; then
        echo -e "${GREEN}✓ SBOM contains nginx references${NC}"
    else
        echo -e "${YELLOW}⚠ Could not find nginx references in SBOM${NC}"
    fi

    # Show file size
    SIZE=$(wc -c < /opt/course/04/sbom.spdx)
    echo -e "  File size: ${SIZE} bytes"

else
    echo -e "${RED}✗ sbom.spdx not found at /opt/course/04/sbom.spdx${NC}"
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
