#!/bin/bash

# Pre-Release Validation Script for Exhibition Buyer App
# 展会采购App预发布验证脚本

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check counters
PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_check() {
    echo -e "${YELLOW}⏳ 检查: $1${NC}"
}

print_pass() {
    echo -e "${GREEN}✓ 通过: $1${NC}"
    ((PASSED++))
}

print_fail() {
    echo -e "${RED}✗ 失败: $1${NC}"
    ((FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠ 警告: $1${NC}"
    ((WARNINGS++))
}

print_suggestion() {
    echo -e "${BLUE}  💡 建议: $1${NC}"
}

# Start validation
print_header "Flutter展会采购App - 预发布验证"
echo "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"

# 1. Flutter Doctor Check
print_header "1. Flutter环境检查"
print_check "运行 flutter doctor"

if flutter doctor > /dev/null 2>&1; then
    print_pass "Flutter环境验证完成"
    flutter doctor -v
else
    print_fail "Flutter环境存在问题"
    print_suggestion "运行 'flutter doctor -v' 查看详细信息并修复问题"
    flutter doctor -v
fi

# 2. Dependencies Check
print_header "2. 依赖完整性检查"
print_check "运行 flutter pub get"

if flutter pub get > /dev/null 2>&1; then
    print_pass "依赖下载完成"
else
    print_fail "依赖下载失败"
    print_suggestion "检查网络连接，或删除 pubspec.lock 后重试"
    exit 1
fi

# 3. Static Analysis
print_header "3. 静态代码分析"
print_check "运行 flutter analyze"

ANALYZE_OUTPUT=$(flutter analyze 2>&1)
if echo "$ANALYZE_OUTPUT" | grep -q "No issues found"; then
    print_pass "代码分析无错误"
elif echo "$ANALYZE_OUTPUT" | grep -q "info •"; then
    print_warning "代码分析发现提示信息"
    echo "$ANALYZE_OUTPUT" | grep "info •" | head -5
    print_suggestion "虽然不影响构建，但建议修复这些提示"
else
    print_fail "代码分析发现错误"
    echo "$ANALYZE_OUTPUT"
    print_suggestion "修复所有错误后再继续"
    exit 1
fi

# 4. Environment File Check
print_header "4. 配置文件验证"
print_check "检查 .env 文件"

if [ ! -f ".env" ]; then
    print_fail ".env 文件不存在"
    print_suggestion "复制 .env.example 为 .env 并填入实际配置"
    exit 1
else
    print_pass ".env 文件存在"
fi

print_check "验证 .env 必需配置项"

ENV_VALID=true

if grep -q "SUPABASE_URL=https://" .env && ! grep -q "SUPABASE_URL=https://your-project-ref" .env; then
    print_pass "SUPABASE_URL 已配置"
else
    print_fail "SUPABASE_URL 未正确配置"
    print_suggestion "在 .env 中设置正确的 SUPABASE_URL"
    ENV_VALID=false
fi

if grep -q "SUPABASE_ANON_KEY=" .env && ! grep -q "SUPABASE_ANON_KEY=your-anon-key" .env; then
    ANON_KEY=$(grep "SUPABASE_ANON_KEY=" .env | cut -d'=' -f2)
    if [ ${#ANON_KEY} -gt 50 ]; then
        print_pass "SUPABASE_ANON_KEY 已配置"
    else
        print_fail "SUPABASE_ANON_KEY 长度不足（可能是占位符）"
        ENV_VALID=false
    fi
else
    print_fail "SUPABASE_ANON_KEY 未配置"
    print_suggestion "在 .env 中设置正确的 SUPABASE_ANON_KEY"
    ENV_VALID=false
fi

if [ "$ENV_VALID" = false ]; then
    exit 1
fi

# 5. Android Manifest Check
print_header "5. Android配置验证"
print_check "检查网络权限"

MANIFEST="android/app/src/main/AndroidManifest.xml"
if grep -q "android.permission.INTERNET" "$MANIFEST"; then
    print_pass "AndroidManifest.xml 包含 INTERNET 权限"
else
    print_fail "AndroidManifest.xml 缺少 INTERNET 权限"
    print_suggestion "在 $MANIFEST 中添加: <uses-permission android:name=\"android.permission.INTERNET\"/>"
    exit 1
fi

# 6. Version Check
print_header "6. 版本号验证"
print_check "检查 pubspec.yaml 版本格式"

VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}')
if [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
    print_pass "版本号格式正确: $VERSION"
else
    print_fail "版本号格式错误: $VERSION"
    print_suggestion "使用格式: major.minor.patch+buildNumber (例如: 1.0.0+1)"
    exit 1
fi

# 7. Assets Check
print_check "验证 assets 配置"

if grep -A 2 "assets:" pubspec.yaml | grep -q ".env"; then
    print_pass ".env 已在 pubspec.yaml assets 中配置"
else
    print_fail ".env 未在 pubspec.yaml assets 中配置"
    print_suggestion "在 pubspec.yaml 的 assets 列表中添加 .env"
    exit 1
fi

# 8. Build Test
print_header "7. Release构建测试"
print_check "执行 flutter build apk --release"

echo "开始构建，这可能需要几分钟..."

if flutter build apk --release; then
    print_pass "APK构建成功"
else
    print_fail "APK构建失败"
    print_suggestion "检查上述构建日志中的错误信息"
    exit 1
fi

# 9. APK Validation
print_header "8. APK文件验证"

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ ! -f "$APK_PATH" ]; then
    print_fail "APK文件不存在: $APK_PATH"
    exit 1
fi

APK_SIZE=$(stat -f%z "$APK_PATH" 2>/dev/null || stat -c%s "$APK_PATH" 2>/dev/null || echo "0")
APK_SIZE_MB=$((APK_SIZE / 1024 / 1024))

print_check "检查APK文件大小"

if [ $APK_SIZE_MB -lt 10 ]; then
    print_fail "APK文件过小 (${APK_SIZE_MB}MB)，可能构建不完整"
    exit 1
elif [ $APK_SIZE_MB -gt 100 ]; then
    print_warning "APK文件较大 (${APK_SIZE_MB}MB)"
    print_suggestion "考虑优化资源文件或启用代码混淆"
else
    print_pass "APK文件大小合理: ${APK_SIZE_MB}MB"
fi

# Final Report
print_header "验证报告"
echo -e "${GREEN}✓ 通过: $PASSED${NC}"
echo -e "${RED}✗ 失败: $FAILED${NC}"
echo -e "${YELLOW}⚠ 警告: $WARNINGS${NC}"
echo ""
echo "APK路径: $APK_PATH"
echo "APK大小: ${APK_SIZE_MB}MB"
echo "版本号: $VERSION"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}🎉 所有检查通过，可以进行真机测试！${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}❌ 发现 $FAILED 个问题，请修复后再测试${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
