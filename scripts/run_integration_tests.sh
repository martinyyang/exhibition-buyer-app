#!/bin/bash

# Integration Test Runner Script
# 用于本地和CI环境运行集成测试

set -e

echo "========================================"
echo "Flutter Integration Tests"
echo "========================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查Flutter环境
echo "检查Flutter环境..."
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter未安装或未在PATH中${NC}"
    exit 1
fi

flutter --version
echo ""

# 检查.env文件
echo "检查环境配置..."
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  .env文件不存在${NC}"
    if [ -f .env.example ]; then
        echo "请复制.env.example为.env并填入正确的配置："
        echo "  cp .env.example .env"
    fi
    exit 1
fi

# 验证环境变量
if ! grep -q "SUPABASE_URL=https://" .env; then
    echo -e "${RED}❌ .env文件中SUPABASE_URL配置无效${NC}"
    exit 1
fi

if ! grep -q "SUPABASE_ANON_KEY=" .env; then
    echo -e "${RED}❌ .env文件中SUPABASE_ANON_KEY配置无效${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 环境配置正常${NC}"
echo ""

# 清理构建缓存
echo "清理构建缓存..."
flutter clean
flutter pub get
echo ""

# 运行测试
TEST_MODE="${1:-all}"
TEST_RESULTS=0

case "$TEST_MODE" in
    "startup")
        echo "运行启动测试..."
        flutter test integration_test/startup_test.dart || TEST_RESULTS=$?
        ;;
    "env")
        echo "运行环境变量测试..."
        flutter test integration_test/env_loading_test.dart || TEST_RESULTS=$?
        ;;
    "error")
        echo "运行错误处理测试..."
        flutter test integration_test/error_handling_test.dart || TEST_RESULTS=$?
        ;;
    "e2e")
        echo "运行完整E2E测试..."
        flutter test integration_test/app_test.dart || TEST_RESULTS=$?
        ;;
    "quick")
        echo "运行快速测试（startup + env + error）..."
        echo ""
        echo "1/3 启动测试..."
        flutter test integration_test/startup_test.dart || TEST_RESULTS=$?
        echo ""
        echo "2/3 环境变量测试..."
        flutter test integration_test/env_loading_test.dart || TEST_RESULTS=$?
        echo ""
        echo "3/3 错误处理测试..."
        flutter test integration_test/error_handling_test.dart || TEST_RESULTS=$?
        ;;
    "all")
        echo "运行所有集成测试..."
        echo ""
        echo "1/4 启动测试..."
        flutter test integration_test/startup_test.dart || TEST_RESULTS=$?
        echo ""
        echo "2/4 环境变量测试..."
        flutter test integration_test/env_loading_test.dart || TEST_RESULTS=$?
        echo ""
        echo "3/4 错误处理测试..."
        flutter test integration_test/error_handling_test.dart || TEST_RESULTS=$?
        echo ""
        echo "4/4 完整E2E测试..."
        flutter test integration_test/app_test.dart || TEST_RESULTS=$?
        ;;
    *)
        echo -e "${RED}❌ 无效的测试模式: $TEST_MODE${NC}"
        echo ""
        echo "用法: $0 [mode]"
        echo "模式选项："
        echo "  startup  - 仅运行启动测试"
        echo "  env      - 仅运行环境变量测试"
        echo "  error    - 仅运行错误处理测试"
        echo "  e2e      - 仅运行完整E2E测试"
        echo "  quick    - 运行快速测试（不含E2E，< 1分钟）"
        echo "  all      - 运行所有测试（默认）"
        exit 1
        ;;
esac

echo ""
echo "========================================"
if [ $TEST_RESULTS -eq 0 ]; then
    echo -e "${GREEN}✓ 所有测试通过${NC}"
    echo "========================================"
    exit 0
else
    echo -e "${RED}❌ 测试失败${NC}"
    echo "========================================"
    exit $TEST_RESULTS
fi
