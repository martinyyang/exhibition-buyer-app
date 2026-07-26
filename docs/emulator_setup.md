# Android 模拟器设置指南

本文档描述如何配置和使用 Android 模拟器进行应用测试。

## 推荐配置

### 系统要求
- Android SDK 安装并配置环境变量
- 至少 8GB RAM（推荐 16GB）
- 至少 10GB 可用存储空间

### 模拟器规格
- **API Level**: 30 (Android 11) 或更高
- **RAM**: 4096 MB
- **Storage**: 2048 MB internal storage
- **架构**: x86_64（启用硬件加速）
- **设备类型**: Pixel 4 或类似设备

## 命令行创建模拟器

### 1. 安装必要组件

```bash
# 安装 Android SDK 平台工具
sdkmanager "platform-tools" "platforms;android-30"

# 安装系统映像（带 Google APIs）
sdkmanager "system-images;android-30;google_apis;x86_64"

# 安装模拟器工具
sdkmanager "emulator" "build-tools;30.0.3"
```

### 2. 创建 AVD（Android Virtual Device）

```bash
# 创建名为 test_emulator 的模拟器
avdmanager create avd \
  --name test_emulator \
  --package "system-images;android-30;google_apis;x86_64" \
  --device "pixel_4"
```

### 3. 配置模拟器参数（可选）

编辑 AVD 配置文件以调整 RAM 和存储：

**Windows**: `%USERPROFILE%\.android\avd\test_emulator.avd\config.ini`
**macOS/Linux**: `~/.android/avd/test_emulator.avd/config.ini`

关键配置：
```ini
hw.ramSize=4096
disk.dataPartition.size=2048M
hw.keyboard=yes
hw.gpu.enabled=yes
hw.gpu.mode=auto
```

## 启动模拟器

### 命令行启动

```bash
# 基础启动
emulator -avd test_emulator

# 无窗口模式启动（适合 CI/CD）
emulator -avd test_emulator -no-window -no-audio

# 启用详细日志
emulator -avd test_emulator -verbose

# 指定端口
emulator -avd test_emulator -port 5554
```

### 推荐启动参数

```bash
emulator -avd test_emulator \
  -no-snapshot-save \
  -wipe-data \
  -no-audio \
  -gpu auto
```

参数说明：
- `-no-snapshot-save`: 不保存快照，每次启动都是干净状态
- `-wipe-data`: 清除数据，确保测试环境一致
- `-no-audio`: 禁用音频（CI 环境不需要）
- `-gpu auto`: 自动检测 GPU 加速

## 检查模拟器状态

### 1. 列出所有模拟器

```bash
# 列出所有 AVD
emulator -list-avds

# 列出正在运行的设备
adb devices
```

### 2. 等待模拟器启动完成

```bash
# 等待设备连接
adb wait-for-device

# 检查启动完成（boot_completed = 1）
adb shell getprop sys.boot_completed

# 完整的等待脚本
while [ "$(adb shell getprop sys.boot_completed 2>/dev/null)" != "1" ]; do
  echo "Waiting for emulator to boot..."
  sleep 2
done
echo "Emulator is ready!"
```

### 3. 检查模拟器健康状态

```bash
# 检查系统属性
adb shell getprop ro.build.version.release  # Android 版本
adb shell getprop ro.build.version.sdk      # API Level
adb shell getprop ro.product.model          # 设备型号

# 检查可用存储
adb shell df /data

# 检查 RAM 使用
adb shell cat /proc/meminfo | grep MemAvailable
```

## 常见问题

### 模拟器启动失败

**错误**: `PANIC: Cannot find AVD system path`
**解决**: 确保已安装对应的系统映像
```bash
sdkmanager "system-images;android-30;google_apis;x86_64"
```

### 模拟器启动缓慢

**原因**: 未启用硬件加速
**解决**: 
- Windows: 确保已安装 Intel HAXM 或启用 Hyper-V
- macOS: 确保已安装 Intel HAXM
- Linux: 确保已启用 KVM

### 模拟器启动后黑屏

**解决**: 尝试不同的 GPU 模式
```bash
emulator -avd test_emulator -gpu swiftshader_indirect
# 或
emulator -avd test_emulator -gpu host
```

## 自动化测试集成

本项目的自动化测试脚本 `scripts/test_on_emulator.sh` 会：
1. 自动检测可用模拟器
2. 如果没有可用模拟器，则创建一个
3. 启动模拟器并等待就绪
4. 安装 APK 并运行测试

参考 `scripts/test_on_emulator.sh` 了解完整实现。

## 清理模拟器

```bash
# 删除 AVD
avdmanager delete avd --name test_emulator

# 清理模拟器缓存（释放磁盘空间）
rm -rf ~/.android/avd/test_emulator.avd
```

## 参考链接

- [Android Emulator 官方文档](https://developer.android.com/studio/run/emulator-commandline)
- [AVD Manager 命令行工具](https://developer.android.com/studio/command-line/avdmanager)
- [ADB 命令参考](https://developer.android.com/studio/command-line/adb)
