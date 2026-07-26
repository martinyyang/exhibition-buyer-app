#!/bin/bash

# 快速验证脚本 - 从构建到模拟器测试一键完成
# 用法: ./scripts/quick_verify.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo ""
    echo "=================================================="
    echo -e "${BLUE}$1${NC}"
    echo "=================================================="
}

# 检查是否在项目根目录
if [ ! -f "pubspec.yaml" ]; then
    print_error "请在项目根目录运行此脚本"
    exit 1
fi

START_TIME=$(date +%s)

# 步骤 1: 清理构建缓存
print_step "步骤 1/4: 清理构建缓存"
print_info "清理 Flutter 构建缓存..."
flutter clean
print_success "清理完成"

# 步骤 2: 获取依赖
print_step "步骤 2/4: 获取依赖"
print_info "运行 flutter pub get..."
flutter pub get
print_success "依赖获取完成"

# 步骤 3: 构建 APK
print_step "步骤 3/4: 构建 Release APK"
print_info "构建中，这可能需要几分钟..."
flutter build apk --release

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    print_success "APK 构建完成: $APK_SIZE"
else
    print_error "APK 构建失败"
    exit 1
fi

# 步骤 4: 模拟器测试
print_step "步骤 4/4: 模拟器自动化测试"

# 检查测试脚本
if [ ! -f "scripts/test_on_emulator.sh" ]; then
    print_error "测试脚本不存在: scripts/test_on_emulator.sh"
    exit 1
fi

# 运行测试
bash scripts/test_on_emulator.sh

TEST_RESULT=$?

# 计算总耗时
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# 最终报告
echo ""
echo "=================================================="
echo "快速验证完成"
echo "=================================================="
echo "总耗时: ${MINUTES}m ${SECONDS}s"
echo ""

if [ $TEST_RESULT -eq 0 ]; then
    print_success "✓ 所有检查通过，可以发布"
else
    print_error "✗ 发现问题，请修复后重试"
fi
echo "=================================================="

exit $TEST_RESULT
