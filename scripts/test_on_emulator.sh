#!/bin/bash

# Android 模拟器自动化测试脚本
# 功能：
# 1. 检测或创建 Android 模拟器
# 2. 启动模拟器并等待就绪
# 3. 安装 APK 并启动应用
# 4. 监控 logcat 输出，检测常见错误
# 5. 生成测试报告

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
AVD_NAME="exhibition_test_emulator"
API_LEVEL="30"
SYSTEM_IMAGE="system-images;android-${API_LEVEL};google_apis;x86_64"
DEVICE_TYPE="pixel_4"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
PACKAGE_NAME="com.example.exhibition_buyer_app"
MAIN_ACTIVITY="${PACKAGE_NAME}/.MainActivity"
BOOT_TIMEOUT=180  # 3 minutes
APP_START_TIMEOUT=30  # 30 seconds
LOG_FILE="emulator_test_$(date +%Y%m%d_%H%M%S).log"
REPORT_FILE="test_report_$(date +%Y%m%d_%H%M%S).txt"

# 错误模式
ERROR_PATTERNS=(
    "no host"
    "UnknownHostException"
    "应用初始化失败"
    "Failed to initialize"
    "SUPABASE_URL not found"
    "SUPABASE_ANON_KEY not found"
    "AndroidRuntime: FATAL EXCEPTION"
    "ANR in"
)

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查必要的工具
check_prerequisites() {
    print_info "检查必要工具..."

    if ! command -v adb &> /dev/null; then
        print_error "adb 未找到，请安装 Android SDK Platform Tools"
        exit 1
    fi

    if ! command -v emulator &> /dev/null; then
        print_error "emulator 未找到，请安装 Android Emulator"
        exit 1
    fi

    if ! command -v avdmanager &> /dev/null; then
        print_error "avdmanager 未找到，请安装 Android SDK Command-line Tools"
        exit 1
    fi

    print_success "所有必要工具已安装"
}

# 检查 APK 是否存在
check_apk() {
    print_info "检查 APK 文件..."

    if [ ! -f "$APK_PATH" ]; then
        print_error "APK 文件不存在: $APK_PATH"
        print_info "请先构建 APK: flutter build apk"
        exit 1
    fi

    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    print_success "找到 APK: $APK_PATH ($APK_SIZE)"
}

# 检查或创建模拟器
ensure_emulator_exists() {
    print_info "检查模拟器..."

    if emulator -list-avds | grep -q "^${AVD_NAME}$"; then
        print_success "模拟器 '$AVD_NAME' 已存在"
        return 0
    fi

    print_warning "模拟器 '$AVD_NAME' 不存在，开始创建..."

    # 检查系统映像是否已安装
    if ! sdkmanager --list_installed | grep -q "$SYSTEM_IMAGE"; then
        print_info "安装系统映像: $SYSTEM_IMAGE"
        yes | sdkmanager "$SYSTEM_IMAGE"
    fi

    # 创建 AVD
    print_info "创建 AVD..."
    echo "no" | avdmanager create avd \
        --name "$AVD_NAME" \
        --package "$SYSTEM_IMAGE" \
        --device "$DEVICE_TYPE" \
        --force

    # 配置 AVD
    AVD_CONFIG=""
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        AVD_CONFIG="$HOME/.android/avd/${AVD_NAME}.avd/config.ini"
    else
        AVD_CONFIG="$HOME/.android/avd/${AVD_NAME}.avd/config.ini"
    fi

    if [ -f "$AVD_CONFIG" ]; then
        print_info "配置 AVD 参数..."
        {
            echo "hw.ramSize=4096"
            echo "disk.dataPartition.size=2048M"
            echo "hw.keyboard=yes"
            echo "hw.gpu.enabled=yes"
            echo "hw.gpu.mode=auto"
        } >> "$AVD_CONFIG"
    fi

    print_success "模拟器创建完成"
}

# 启动模拟器
start_emulator() {
    print_info "检查是否有正在运行的模拟器..."

    RUNNING_DEVICES=$(adb devices | grep -v "List of devices" | grep "device$" | wc -l)
    if [ "$RUNNING_DEVICES" -gt 0 ]; then
        print_success "发现正在运行的模拟器，跳过启动"
        return 0
    fi

    print_info "启动模拟器 '$AVD_NAME'..."

    # 在后台启动模拟器
    emulator -avd "$AVD_NAME" \
        -no-snapshot-save \
        -no-audio \
        -gpu auto \
        -no-boot-anim \
        > "$LOG_FILE" 2>&1 &

    EMULATOR_PID=$!
    print_info "模拟器进程 PID: $EMULATOR_PID"

    # 等待设备连接
    print_info "等待模拟器连接..."
    adb wait-for-device

    # 等待启动完成
    print_info "等待模拟器启动完成（最多 ${BOOT_TIMEOUT}s）..."
    ELAPSED=0
    while [ "$(adb shell getprop sys.boot_completed 2>/dev/null)" != "1" ]; do
        if [ $ELAPSED -ge $BOOT_TIMEOUT ]; then
            print_error "模拟器启动超时"
            kill $EMULATOR_PID 2>/dev/null || true
            exit 1
        fi
        echo -n "."
        sleep 2
        ELAPSED=$((ELAPSED + 2))
    done
    echo ""

    print_success "模拟器启动完成（耗时 ${ELAPSED}s）"

    # 显示设备信息
    print_info "设备信息:"
    echo "  Android 版本: $(adb shell getprop ro.build.version.release)"
    echo "  API Level: $(adb shell getprop ro.build.version.sdk)"
    echo "  设备型号: $(adb shell getprop ro.product.model)"
}

# 安装 APK
install_apk() {
    print_info "安装 APK..."

    # 卸载旧版本（如果存在）
    if adb shell pm list packages | grep -q "$PACKAGE_NAME"; then
        print_info "卸载旧版本..."
        adb uninstall "$PACKAGE_NAME" || true
    fi

    # 安装新版本
    if adb install -r "$APK_PATH"; then
        print_success "APK 安装成功"
    else
        print_error "APK 安装失败"
        exit 1
    fi
}

# 启动应用并监控日志
start_and_monitor_app() {
    print_info "清空 logcat 缓冲区..."
    adb logcat -c

    print_info "启动应用..."
    adb shell am start -n "$MAIN_ACTIVITY"

    print_info "监控 logcat 输出（${APP_START_TIMEOUT}s）..."

    # 创建临时日志文件
    LOGCAT_FILE="logcat_${LOG_FILE}"

    # 启动 logcat 捕获
    timeout $APP_START_TIMEOUT adb logcat -v time > "$LOGCAT_FILE" 2>&1 || true

    print_success "日志捕获完成"
}

# 分析日志
analyze_logs() {
    print_info "分析日志..."

    ERRORS_FOUND=()
    WARNINGS_FOUND=()

    # 检查致命错误
    for pattern in "${ERROR_PATTERNS[@]}"; do
        if grep -qi "$pattern" "$LOGCAT_FILE"; then
            ERRORS_FOUND+=("$pattern")
        fi
    done

    # 检查启动挂起
    LAST_LOG_TIME=$(tail -n 1 "$LOGCAT_FILE" | awk '{print $2}')
    if [ -z "$LAST_LOG_TIME" ]; then
        WARNINGS_FOUND+=("No logs captured - app may have failed to start")
    fi

    # 检查成功标志
    INIT_SUCCESS=false
    if grep -q "✓ Loaded .env file successfully" "$LOGCAT_FILE"; then
        INIT_SUCCESS=true
    elif grep -q "✓ Using fallback configuration" "$LOGCAT_FILE"; then
        INIT_SUCCESS=true
        WARNINGS_FOUND+=("Using fallback configuration (missing .env file)")
    fi

    # 检查 Supabase 初始化
    if grep -q "Initializing Supabase" "$LOGCAT_FILE"; then
        print_success "检测到 Supabase 初始化"
    else
        WARNINGS_FOUND+=("Did not detect Supabase initialization")
    fi

    # 生成报告
    generate_report
}

# 生成测试报告
generate_report() {
    print_info "生成测试报告..."

    {
        echo "==============================================="
        echo "Android 模拟器测试报告"
        echo "==============================================="
        echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "APK: $APK_PATH"
        echo "包名: $PACKAGE_NAME"
        echo ""

        echo "设备信息:"
        echo "  Android 版本: $(adb shell getprop ro.build.version.release)"
        echo "  API Level: $(adb shell getprop ro.build.version.sdk)"
        echo "  设备型号: $(adb shell getprop ro.product.model)"
        echo ""

        echo "==============================================="
        echo "测试结果"
        echo "==============================================="

        if [ ${#ERRORS_FOUND[@]} -eq 0 ]; then
            echo "✓ 未发现致命错误"
        else
            echo "✗ 发现 ${#ERRORS_FOUND[@]} 个致命错误:"
            for error in "${ERRORS_FOUND[@]}"; do
                echo "  - $error"
            done
        fi

        echo ""

        if [ ${#WARNINGS_FOUND[@]} -eq 0 ]; then
            echo "✓ 未发现警告"
        else
            echo "⚠ 发现 ${#WARNINGS_FOUND[@]} 个警告:"
            for warning in "${WARNINGS_FOUND[@]}"; do
                echo "  - $warning"
            done
        fi

        echo ""
        echo "==============================================="
        echo "关键日志片段"
        echo "==============================================="

        # 显示初始化相关日志
        echo ""
        echo "### 应用初始化 ###"
        grep -i "flutter\|supabase\|\.env\|init" "$LOGCAT_FILE" | head -n 20 || echo "No initialization logs found"

        # 显示错误日志
        if [ ${#ERRORS_FOUND[@]} -gt 0 ]; then
            echo ""
            echo "### 错误日志 ###"
            for pattern in "${ERROR_PATTERNS[@]}"; do
                grep -i "$pattern" "$LOGCAT_FILE" | head -n 5 || true
            done
        fi

        echo ""
        echo "==============================================="
        echo "完整日志文件: $LOGCAT_FILE"
        echo "==============================================="

    } > "$REPORT_FILE"

    # 打印报告内容
    cat "$REPORT_FILE"

    print_success "报告已保存: $REPORT_FILE"

    # 返回测试结果
    if [ ${#ERRORS_FOUND[@]} -eq 0 ]; then
        print_success "✓ 测试通过 - 未发现致命错误"
        return 0
    else
        print_error "✗ 测试失败 - 发现 ${#ERRORS_FOUND[@]} 个致命错误"
        return 1
    fi
}

# 清理
cleanup() {
    print_info "清理..."

    # 可选：停止应用
    # adb shell am force-stop "$PACKAGE_NAME"

    # 可选：关闭模拟器
    # adb emu kill

    print_info "保留模拟器运行，可手动测试"
}

# 主函数
main() {
    echo "=================================================="
    echo "Android 模拟器自动化测试"
    echo "=================================================="
    echo ""

    check_prerequisites
    check_apk
    ensure_emulator_exists
    start_emulator
    install_apk
    start_and_monitor_app
    analyze_logs

    TEST_RESULT=$?

    cleanup

    echo ""
    echo "=================================================="
    if [ $TEST_RESULT -eq 0 ]; then
        print_success "测试完成 - 所有检查通过"
    else
        print_error "测试完成 - 发现问题，请查看报告"
    fi
    echo "=================================================="

    exit $TEST_RESULT
}

# 运行主函数
main "$@"
