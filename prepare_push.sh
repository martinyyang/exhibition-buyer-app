#!/bin/bash

# Final Push Preparation Script
# This script prepares the project for GitHub Pages deployment

set -e

echo "========================================"
echo "GitHub Pages Deployment Preparation"
echo "========================================"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Update base href for GitHub Pages${NC}"
echo "Current base href in web/index.html:"
grep 'base href' web/index.html

echo ""
echo -e "${BLUE}Updating to production base href...${NC}"
sed -i 's|<base href="\$FLUTTER_BASE_HREF">|<base href="/exhibition-buyer-app/">|' web/index.html

echo "Updated base href:"
grep 'base href' web/index.html
echo -e "${GREEN}✓ Base href updated${NC}"
echo ""

echo -e "${YELLOW}Step 2: Rebuild for production${NC}"
echo -e "${BLUE}Running: flutter build web --release --base-href /exhibition-buyer-app/${NC}"
flutter build web --release --base-href /exhibition-buyer-app/

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Production build completed${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}Step 3: Verify build artifacts${NC}"
if [ -f "build/web/main.dart.js" ]; then
    BUILD_SIZE=$(du -h build/web/main.dart.js | cut -f1)
    echo -e "${GREEN}✓ main.dart.js exists (${BUILD_SIZE})${NC}"
else
    echo -e "${RED}✗ main.dart.js not found${NC}"
    exit 1
fi

if [ -f "build/web/index.html" ]; then
    echo -e "${GREEN}✓ index.html exists${NC}"
    # Verify base href in built file
    if grep -q 'base href="/exhibition-buyer-app/"' build/web/index.html; then
        echo -e "${GREEN}✓ Base href correctly set in build${NC}"
    else
        echo -e "${RED}✗ Base href not correct in build${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ index.html not found${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}Step 4: Check git status${NC}"
git status --short

echo ""
echo -e "${YELLOW}Step 5: Stage changes${NC}"
echo "Staging files..."
git add web/index.html
git add build/
git add .github/workflows/ci.yml
git add lib/
git add test/
git add *.md
git add *.sh
git add *.bat

echo -e "${GREEN}✓ Files staged${NC}"
echo ""

echo -e "${YELLOW}Step 6: Review changes to commit${NC}"
git status --short
echo ""

echo "========================================"
echo -e "${GREEN}Ready to commit and push!${NC}"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Review the staged changes above"
echo "  2. Run: git commit -m \"Fix RLS policies and enable web deployment\""
echo "  3. Run: git push origin master"
echo "  4. Monitor: https://github.com/martinyyang/exhibition-buyer-app/actions"
echo "  5. After deployment succeeds:"
echo "     - Test: https://martinyyang.github.io/exhibition-buyer-app/"
echo "     - Regenerate Supabase service_role key"
echo ""
echo "========================================"
