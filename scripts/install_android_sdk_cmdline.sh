#!/bin/bash

# 一键自动安装 Android SDK（命令行版本 - 轻量级）
# 适用于快速设置 CI/CD 或不想安装完整 Android Studio 的情况

set -e

echo "=========================================="
echo "  Android SDK 命令行工具自动安装"
echo "=========================================="
echo ""
echo "⚠️  注意: 这是轻量级安装（约 5-8 GB）"
echo "    如果需要图形界面和更好的体验，请手动安装 Android Studio"
echo "    访问: https://developer.android.com/studio"
echo ""

# 检查是否已安装
if [ -d "$ANDROID_HOME" ] && [ -f "$ANDROID_HOME/platform-tools/adb" ]; then
    echo "✓ Android SDK 似乎已安装"
    echo "  位置: $ANDROID_HOME"
    echo ""
    read -p "是否继续安装？这将覆盖现有配置 (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "安装已取消"
        exit 0
    fi
fi

# 设置安装路径
if [ -z "$ANDROID_HOME" ]; then
    DEFAULT_SDK_PATH="$HOME/Android/Sdk"
    read -p "请输入 Android SDK 安装路径 [默认: $DEFAULT_SDK_PATH]: " SDK_PATH
    SDK_PATH=${SDK_PATH:-$DEFAULT_SDK_PATH}
else
    SDK_PATH="$ANDROID_HOME"
fi

echo ""
echo "安装路径: $SDK_PATH"
echo ""

# 创建目录
mkdir -p "$SDK_PATH"
cd "$SDK_PATH"

# 下载命令行工具
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
CMDLINE_TOOLS_FILE="cmdline-tools.zip"

echo "=========================================="
echo "步骤 1/5: 下载命令行工具"
echo "=========================================="
echo "下载地址: $CMDLINE_TOOLS_URL"
echo "下载大小: 约 150 MB"
echo ""

if command -v curl &> /dev/null; then
    curl -L -o "$CMDLINE_TOOLS_FILE" "$CMDLINE_TOOLS_URL"
elif command -v wget &> /dev/null; then
    wget -O "$CMDLINE_TOOLS_FILE" "$CMDLINE_TOOLS_URL"
else
    echo "错误: 需要 curl 或 wget 来下载文件"
    echo "请手动下载: $CMDLINE_TOOLS_URL"
    echo "并解压到: $SDK_PATH/cmdline-tools/latest"
    exit 1
fi

echo "✓ 下载完成"
echo ""

# 解压
echo "=========================================="
echo "步骤 2/5: 解压命令行工具"
echo "=========================================="

if command -v unzip &> /dev/null; then
    unzip -q "$CMDLINE_TOOLS_FILE"
    rm "$CMDLINE_TOOLS_FILE"

    # 重命名目录结构
    mkdir -p cmdline-tools
    mv cmdline-tools cmdline-tools/latest 2>/dev/null || true

    echo "✓ 解压完成"
else
    echo "错误: 需要 unzip 工具"
    echo "请手动解压 $CMDLINE_TOOLS_FILE"
    exit 1
fi

echo ""

# 设置环境变量
echo "=========================================="
echo "步骤 3/5: 配置环境变量"
echo "=========================================="

export ANDROID_HOME="$SDK_PATH"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"

echo "export ANDROID_HOME=\"$SDK_PATH\"" >> ~/.bashrc
echo "export PATH=\"\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/emulator\"" >> ~/.bashrc

echo "✓ 环境变量已添加到 ~/.bashrc"
echo ""

# 安装 SDK 组件
echo "=========================================="
echo "步骤 4/5: 安装 SDK 组件"
echo "=========================================="
echo "安装以下组件:"
echo "  - platform-tools (adb)"
echo "  - Android 34 (API 34)"
echo "  - build-tools 34.0.0"
echo "  - emulator"
echo "  - system-images (Android 34 x86_64)"
echo ""

cd "$SDK_PATH/cmdline-tools/latest/bin"

# 自动接受许可
yes | ./sdkmanager --licenses 2>/dev/null || true

# 安装组件
./sdkmanager "platform-tools"
./sdkmanager "platforms;android-34"
./sdkmanager "build-tools;34.0.0"
./sdkmanager "emulator"
./sdkmanager "system-images;android-34;google_apis;x86_64"

echo "✓ SDK 组件安装完成"
echo ""

# 配置 Flutter
echo "=========================================="
echo "步骤 5/5: 配置 Flutter"
echo "=========================================="

flutter config --android-sdk "$SDK_PATH"
flutter doctor --android-licenses

echo "✓ Flutter 配置完成"
echo ""

# 验证安装
echo "=========================================="
echo "验证安装"
echo "=========================================="

flutter doctor -v

echo ""
echo "=========================================="
echo "安装完成！"
echo "=========================================="
echo ""
echo "Android SDK 位置: $SDK_PATH"
echo ""
echo "下一步:"
echo "  1. 重启终端使环境变量生效"
echo "  2. 运行测试:"
echo "     cd $PWD"
echo "     bash scripts/quick_verify.sh"
echo ""
echo "创建模拟器 (可选):"
echo "  avdmanager create avd -n test_device -k \"system-images;android-34;google_apis;x86_64\""
echo "  emulator -avd test_device"
echo ""
