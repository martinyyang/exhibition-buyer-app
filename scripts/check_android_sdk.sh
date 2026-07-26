#!/bin/bash

# Android SDK 快速安装脚本
# 自动检测系统并提供安装指引

echo "=========================================="
echo "  Android SDK 安装状态检查"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查 Android SDK
echo -e "${BLUE}[1/5] 检查 Android SDK...${NC}"
if [ -d "$ANDROID_HOME" ]; then
    echo -e "${GREEN}✓ ANDROID_HOME 已设置: $ANDROID_HOME${NC}"
    SDK_EXISTS=true
else
    # 尝试常见位置
    POSSIBLE_PATHS=(
        "$HOME/AppData/Local/Android/Sdk"
        "/c/Users/$USER/AppData/Local/Android/Sdk"
        "C:/Users/$USER/AppData/Local/Android/Sdk"
        "$LOCALAPPDATA/Android/Sdk"
    )

    SDK_EXISTS=false
    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -d "$path" ]; then
            echo -e "${YELLOW}⚠ 发现 SDK 但 ANDROID_HOME 未设置: $path${NC}"
            echo "  运行: export ANDROID_HOME=\"$path\""
            SDK_EXISTS=true
            break
        fi
    done

    if [ "$SDK_EXISTS" = false ]; then
        echo -e "${RED}✗ Android SDK 未找到${NC}"
    fi
fi

echo ""

# 检查 adb
echo -e "${BLUE}[2/5] 检查 Android Platform Tools (adb)...${NC}"
if command -v adb &> /dev/null; then
    ADB_VERSION=$(adb version 2>&1 | head -1)
    echo -e "${GREEN}✓ adb 已安装: $ADB_VERSION${NC}"
else
    echo -e "${RED}✗ adb 未找到${NC}"
fi

echo ""

# 检查 Java
echo -e "${BLUE}[3/5] 检查 Java...${NC}"
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -1)
    echo -e "${GREEN}✓ Java 已安装: $JAVA_VERSION${NC}"
else
    echo -e "${RED}✗ Java 未找到${NC}"
fi

echo ""

# 检查模拟器
echo -e "${BLUE}[4/5] 检查 Android Emulator...${NC}"
if command -v emulator &> /dev/null; then
    echo -e "${GREEN}✓ emulator 已安装${NC}"
    AVDS=$(emulator -list-avds 2>/dev/null)
    if [ -n "$AVDS" ]; then
        echo "  可用模拟器:"
        echo "$AVDS" | sed 's/^/    - /'
    else
        echo -e "${YELLOW}  ⚠ 未创建模拟器${NC}"
    fi
else
    echo -e "${RED}✗ emulator 未找到${NC}"
fi

echo ""

# Flutter Doctor
echo -e "${BLUE}[5/5] 运行 flutter doctor...${NC}"
flutter doctor -v | grep -A5 "Android toolchain"

echo ""
echo "=========================================="
echo "  安装建议"
echo "=========================================="
echo ""

if [ "$SDK_EXISTS" = false ]; then
    echo -e "${YELLOW}Android SDK 未安装${NC}"
    echo ""
    echo "请选择安装方式:"
    echo ""
    echo "【推荐】方法 1: 完整安装 Android Studio"
    echo "  1. 访问: https://developer.android.com/studio"
    echo "  2. 下载 Windows 版本 (约 1.1 GB)"
    echo "  3. 运行安装程序，选择 Standard 安装"
    echo "  4. 完成后运行:"
    echo "     flutter doctor --android-licenses"
    echo "     flutter doctor -v"
    echo ""
    echo "方法 2: 仅命令行工具（轻量）"
    echo "  1. 访问: https://developer.android.com/studio#command-line-tools-only"
    echo "  2. 下载 commandlinetools-win (约 150 MB)"
    echo "  3. 按照 docs/ANDROID_SDK_SETUP.md 配置"
    echo ""
    echo "详细文档: docs/ANDROID_SDK_SETUP.md"
else
    echo -e "${GREEN}Android SDK 已安装！${NC}"
    echo ""
    echo "下一步:"
    echo "  1. 确保环境变量正确:"
    echo "     export ANDROID_HOME=\"<SDK路径>\""
    echo "     export PATH=\$PATH:\$ANDROID_HOME/platform-tools"
    echo ""
    echo "  2. 接受许可协议:"
    echo "     flutter doctor --android-licenses"
    echo ""
    echo "  3. 运行完整测试:"
    echo "     bash scripts/quick_verify.sh"
fi

echo ""
echo "=========================================="
