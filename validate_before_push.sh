#!/bin/bash

# Pre-Deployment Validation Script for Flutter Web
# This script validates all aspects of the web build before pushing to GitHub

set -e  # Exit on first error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Tracking
ERRORS=0
WARNINGS=0

echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}Pre-Deployment Validation Script${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""

# Helper functions
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
        return 0
    else
        echo -e "${RED}✗ $1${NC}"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

check_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    WARNINGS=$((WARNINGS + 1))
}

check_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ==========================================
# Step 1: Environment Check
# ==========================================
echo -e "${BLUE}[1/7] Checking environment...${NC}"

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter is not installed or not in PATH${NC}"
    exit 1
fi
check_success "Flutter is installed"

FLUTTER_VERSION=$(flutter --version | head -n 1)
check_info "Flutter version: $FLUTTER_VERSION"

# Check if web support is enabled (check both devices and config)
if flutter devices 2>&1 | grep -qi "chrome\|edge\|web"; then
    check_success "Flutter web support is available"
else
    check_warning "No web browsers detected. Ensure Chrome/Edge is installed."
fi

echo ""

# ==========================================
# Step 2: Critical Files Check
# ==========================================
echo -e "${BLUE}[2/7] Checking critical files...${NC}"

# Check main.dart
if [ -f "lib/main.dart" ]; then
    check_success "lib/main.dart exists"
else
    echo -e "${RED}✗ lib/main.dart is missing${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check web/index.html
if [ -f "web/index.html" ]; then
    check_success "web/index.html exists"

    # Verify base href
    if grep -q '<base href="/">' web/index.html; then
        check_success "web/index.html has correct base href placeholder"
    else
        check_warning "web/index.html base href may not be correct"
    fi
else
    echo -e "${RED}✗ web/index.html is missing${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check web/manifest.json
if [ -f "web/manifest.json" ]; then
    check_success "web/manifest.json exists"
else
    check_warning "web/manifest.json is missing (recommended for PWA)"
fi

# Check .env file
if [ -f ".env" ]; then
    check_success ".env file exists"

    # Verify environment variables
    if grep -q "SUPABASE_URL" .env && grep -q "SUPABASE_ANON_KEY" .env; then
        check_success "Environment variables are configured"
    else
        check_warning "Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env"
    fi
else
    check_warning ".env file missing (fallback will be used)"
fi

# Check key service files
KEY_FILES=(
    "lib/core/services/supabase_client.dart"
    "lib/core/router/app_router.dart"
    "lib/features/auth/services/auth_service.dart"
)

for file in "${KEY_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_success "$file exists"
    else
        check_warning "$file is missing"
    fi
done

echo ""

# ==========================================
# Step 3: Clean and Get Dependencies
# ==========================================
echo -e "${BLUE}[3/7] Cleaning and fetching dependencies...${NC}"

flutter clean > /dev/null 2>&1
check_success "flutter clean completed"

flutter pub get > /dev/null 2>&1
check_success "flutter pub get completed"

echo ""

# ==========================================
# Step 4: Code Analysis
# ==========================================
echo -e "${BLUE}[4/7] Running flutter analyze...${NC}"

ANALYZE_OUTPUT=$(flutter analyze 2>&1)
ANALYZE_EXIT=$?

if [ $ANALYZE_EXIT -eq 0 ]; then
    check_success "No analysis errors found"
else
    # Check for errors vs warnings
    ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "error •" || true)
    WARNING_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "warning •" || true)
    INFO_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "info •" || true)

    if [ $ERROR_COUNT -gt 0 ]; then
        echo -e "${RED}✗ Found $ERROR_COUNT analysis error(s)${NC}"
        echo "$ANALYZE_OUTPUT" | grep "error •"
        ERRORS=$((ERRORS + ERROR_COUNT))
    else
        check_success "No critical analysis errors"
    fi

    if [ $WARNING_COUNT -gt 0 ]; then
        check_warning "Found $WARNING_COUNT analysis warning(s) (acceptable)"
    fi

    if [ $INFO_COUNT -gt 0 ]; then
        check_info "Found $INFO_COUNT info message(s)"
    fi
fi

echo ""

# ==========================================
# Step 5: Build Web Release
# ==========================================
echo -e "${BLUE}[5/7] Building web release...${NC}"
check_info "This may take a few minutes..."

if flutter build web --release > /dev/null 2>&1; then
    check_success "flutter build web --release completed successfully"
else
    echo -e "${RED}✗ Build failed${NC}"
    echo "Run 'flutter build web --release' manually to see errors"
    ERRORS=$((ERRORS + 1))
    exit 1
fi

echo ""

# ==========================================
# Step 6: Build Artifacts Validation
# ==========================================
echo -e "${BLUE}[6/7] Validating build artifacts...${NC}"

if [ -d "build/web" ]; then
    check_success "build/web directory exists"
else
    echo -e "${RED}✗ build/web directory not found${NC}"
    ERRORS=$((ERRORS + 1))
    exit 1
fi

# Check for main.dart.js
if [ -f "build/web/main.dart.js" ]; then
    check_success "main.dart.js generated"

    # Check file size
    FILE_SIZE=$(stat -c%s "build/web/main.dart.js" 2>/dev/null || stat -f%z "build/web/main.dart.js" 2>/dev/null)
    FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))

    if [ $FILE_SIZE_MB -lt 5 ]; then
        check_success "main.dart.js size is acceptable (${FILE_SIZE_MB}MB)"
    else
        check_warning "main.dart.js is large (${FILE_SIZE_MB}MB) - consider code splitting"
    fi
else
    echo -e "${RED}✗ main.dart.js not found in build output${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check for flutter.js
if [ -f "build/web/flutter.js" ]; then
    check_success "flutter.js generated"
else
    check_warning "flutter.js not found (may be loaded from CDN)"
fi

# Check for index.html
if [ -f "build/web/index.html" ]; then
    check_success "index.html generated"
else
    echo -e "${RED}✗ index.html not found in build output${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check for assets
if [ -d "build/web/assets" ]; then
    check_success "assets directory generated"
else
    check_warning "assets directory not found"
fi

echo ""

# ==========================================
# Step 7: Summary
# ==========================================
echo -e "${BLUE}[7/7] Validation Summary${NC}"
echo -e "${BLUE}=================================${NC}"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo -e "${GREEN}✓ Build is ready for deployment${NC}"

    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ $WARNINGS warning(s) found (review recommended)${NC}"
    fi

    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Review PRE_DEPLOYMENT_CHECKLIST.md for manual checks"
    echo "  2. Commit and push changes"
    echo "  3. GitHub Actions will deploy automatically"
    echo ""
    exit 0
else
    echo -e "${RED}✗ $ERRORS critical error(s) found${NC}"

    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    fi

    echo ""
    echo -e "${RED}❌ Build is NOT ready for deployment${NC}"
    echo -e "${RED}Please fix the errors above before pushing${NC}"
    echo ""
    exit 1
fi
