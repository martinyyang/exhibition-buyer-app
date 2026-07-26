#!/bin/bash

# Release APK 冒烟测试脚本
# 用途：构建 Release APK 并在模拟器上执行基础功能测试
# 目标：确保 APK 能启动、不崩溃、不卡住

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试报告变量
TEST_RESULTS=()
FAILED_TESTS=0
PASSED_TESTS=0

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_test_pass() {
    echo -e "${GREEN}✓${NC} $1"
    TEST_RESULTS+=("PASS: $1")
    ((PASSED_TESTS++))
}

log_test_fail() {
    echo -e "${RED}✗${NC} $1"
    TEST_RESULTS+=("FAIL: $1")
    ((FAILED_TESTS++))
}

# 清理函数
cleanup() {
    log_info "执行清理操作..."
    if [ ! -z "$DEVICE_ID" ]; then
        adb -s "$DEVICE_ID" uninstall com.example.exhibition_buyer_app 2>/dev/null || true
    fi
}

trap cleanup EXIT

# 步骤1：检查环境
log_info "步骤 1/7: 检查测试环境..."

if ! command -v flutter &> /dev/null; then
    log_error "Flutter 未安装"
    exit 1
fi

if ! command -v adb &> /dev/null; then
    log_error "ADB 未安装"
    exit 1
fi

log_test_pass "Flutter 和 ADB 已安装"

# 步骤2：检查模拟器
log_info "步骤 2/7: 检查 Android 模拟器..."

DEVICE_ID=$(adb devices | grep -w "device" | head -n 1 | awk '{print $1}')

if [ -z "$DEVICE_ID" ]; then
    log_error "未检测到 Android 设备或模拟器"
    log_info "请先启动模拟器：flutter emulators --launch <emulator_id>"
    log_info "或连接真机并启用 USB 调试"
    exit 1
fi

log_test_pass "检测到设备: $DEVICE_ID"

# 检查设备状态
DEVICE_STATE=$(adb -s "$DEVICE_ID" get-state 2>/dev/null)
if [ "$DEVICE_STATE" != "device" ]; then
    log_error "设备状态异常: $DEVICE_STATE"
    exit 1
fi

log_test_pass "设备状态正常"

# 步骤3：构建 Release APK
log_info "步骤 3/7: 构建 Release APK..."

if [ ! -f ".env" ]; then
    log_warn ".env 文件不存在，将使用默认配置"
fi

flutter clean > /dev/null 2>&1
flutter pub get > /dev/null 2>&1

BUILD_START=$(date +%s)
if flutter build apk --release; then
    BUILD_END=$(date +%s)
    BUILD_TIME=$((BUILD_END - BUILD_START))
    log_test_pass "Release APK 构建成功 (耗时: ${BUILD_TIME}s)"
else
    log_test_fail "Release APK 构建失败"
    exit 1
fi

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK_PATH" ]; then
    log_test_fail "APK 文件不存在: $APK_PATH"
    exit 1
fi

APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
log_info "APK 大小: $APK_SIZE"

# 步骤4：安装 APK
log_info "步骤 4/7: 安装 Release APK 到设备..."

# 卸载旧版本
adb -s "$DEVICE_ID" uninstall com.example.exhibition_buyer_app 2>/dev/null || true

INSTALL_START=$(date +%s)
if adb -s "$DEVICE_ID" install "$APK_PATH" > /dev/null 2>&1; then
    INSTALL_END=$(date +%s)
    INSTALL_TIME=$((INSTALL_END - INSTALL_START))
    log_test_pass "APK 安装成功 (耗时: ${INSTALL_TIME}s)"
else
    log_test_fail "APK 安装失败"
    exit 1
fi

# 步骤5：启动应用并检测崩溃
log_info "步骤 5/7: 启动应用并监控启动过程..."

# 清除 logcat 缓存
adb -s "$DEVICE_ID" logcat -c

# 后台启动 logcat 监控
LOGCAT_FILE="/tmp/smoke_test_logcat_$$.log"
adb -s "$DEVICE_ID" logcat -v time > "$LOGCAT_FILE" &
LOGCAT_PID=$!

# 启动应用
adb -s "$DEVICE_ID" shell am start -n com.example.exhibition_buyer_app/.MainActivity > /dev/null 2>&1

log_info "等待应用启动 (15秒超时)..."
sleep 15

# 停止 logcat
kill $LOGCAT_PID 2>/dev/null || true

# 检查应用是否崩溃
if grep -q "FATAL EXCEPTION" "$LOGCAT_FILE"; then
    log_test_fail "应用启动时崩溃 (FATAL EXCEPTION)"
    log_error "崩溃日志："
    grep -A 10 "FATAL EXCEPTION" "$LOGCAT_FILE"
    rm -f "$LOGCAT_FILE"
    exit 1
else
    log_test_pass "应用启动无崩溃"
fi

# 检查应用是否卡住 (ANR)
if grep -q "ANR in com.example.exhibition_buyer_app" "$LOGCAT_FILE"; then
    log_test_fail "应用启动时卡住 (ANR)"
    log_error "ANR 日志："
    grep -A 10 "ANR in" "$LOGCAT_FILE"
    rm -f "$LOGCAT_FILE"
    exit 1
else
    log_test_pass "应用启动无卡顿 (ANR)"
fi

# 检查 .env 文件加载
if grep -q "flutter_dotenv" "$LOGCAT_FILE" && grep -q "Error" "$LOGCAT_FILE"; then
    log_warn ".env 加载可能存在问题"
    grep "flutter_dotenv" "$LOGCAT_FILE" | tail -5
else
    log_test_pass ".env 配置加载正常"
fi

# 步骤6：检查应用进程
log_info "步骤 6/7: 检查应用进程状态..."

PROCESS_INFO=$(adb -s "$DEVICE_ID" shell "ps | grep com.example.exhibition_buyer_app" 2>/dev/null || \
               adb -s "$DEVICE_ID" shell "ps -A | grep com.example.exhibition_buyer_app" 2>/dev/null)

if [ -z "$PROCESS_INFO" ]; then
    log_test_fail "应用进程未运行"
    rm -f "$LOGCAT_FILE"
    exit 1
else
    log_test_pass "应用进程正在运行"
    log_info "进程信息: $PROCESS_INFO"
fi

# 步骤7：检查网络请求能力
log_info "步骤 7/7: 检查网络请求能力..."

# 检查是否有网络请求日志
if grep -q "Supabase" "$LOGCAT_FILE" || grep -q "http" "$LOGCAT_FILE"; then
    log_test_pass "应用可以发起网络请求"
else
    log_warn "未检测到网络请求 (可能需要手动验证)"
fi

# 清理临时文件
rm -f "$LOGCAT_FILE"

# 生成测试报告
log_info "==============================================="
log_info "冒烟测试完成"
log_info "==============================================="
log_info "通过测试: $PASSED_TESTS"
log_info "失败测试: $FAILED_TESTS"
log_info "-----------------------------------------------"

for result in "${TEST_RESULTS[@]}"; do
    echo "$result"
done

log_info "-----------------------------------------------"

if [ $FAILED_TESTS -eq 0 ]; then
    log_info "✅ 冒烟测试全部通过！Release APK 可以发布"
    exit 0
else
    log_error "❌ 冒烟测试失败！请修复问题后重新测试"
    exit 1
fi
