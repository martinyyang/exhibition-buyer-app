# Android SDK 安装指南

**目标**：安装 Android SDK 以支持本地 APK 构建和模拟器测试

---

## 📋 安装前检查

运行以下命令检查当前状态：
```bash
flutter doctor -v
```

如果看到：
```
[X] Android toolchain - develop for Android devices
    X Unable to locate Android SDK.
```

说明需要安装 Android SDK。

---

## 🚀 安装步骤

### 方法 1：完整安装 Android Studio（推荐，适合长期开发）

#### 1. 下载 Android Studio

访问官网下载：
- **官网**：https://developer.android.com/studio
- **直接下载**（Windows）：https://redirector.gvt1.com/edgedl/android/studio/install/2024.2.1.12/android-studio-2024.2.1.12-windows.exe
- 文件大小：约 1.1 GB
- 安装后占用：约 10-15 GB

#### 2. 安装 Android Studio

1. 运行下载的 `.exe` 文件
2. 安装向导选择：
   - ✅ **Android SDK**
   - ✅ **Android SDK Platform**
   - ✅ **Android Virtual Device** (模拟器)
3. 默认安装位置：
   ```
   C:\Program Files\Android\Android Studio
   C:\Users\<你的用户名>\AppData\Local\Android\Sdk
   ```
4. 完成安装（大约 10-15 分钟）

#### 3. 首次启动配置

1. 启动 Android Studio
2. 选择 **Standard** 安装类型
3. SDK Components Setup：
   - ✅ Android SDK Platform 34 (或最新版本)
   - ✅ Android SDK Build-Tools
   - ✅ Android Emulator
   - ✅ Android SDK Platform-Tools
4. 点击 **Finish**，等待下载完成（约 5-10 分钟）

#### 4. 配置环境变量（重要！）

**方式 A：通过 Flutter 自动配置**
```bash
# Flutter 会自动检测 Android Studio 安装
flutter doctor -v

# 如果仍未检测到，手动指定 SDK 路径
flutter config --android-sdk "C:\Users\<你的用户名>\AppData\Local\Android\Sdk"
```

**方式 B：手动配置系统环境变量**

1. 右键 **此电脑** → **属性** → **高级系统设置** → **环境变量**
2. 在 **用户变量** 中添加：
   ```
   变量名: ANDROID_HOME
   变量值: C:\Users\<你的用户名>\AppData\Local\Android\Sdk
   ```
3. 编辑 **Path** 变量，添加：
   ```
   %ANDROID_HOME%\platform-tools
   %ANDROID_HOME%\tools
   %ANDROID_HOME%\emulator
   ```
4. 点击 **确定** 保存

#### 5. 接受 Android 许可协议

```bash
flutter doctor --android-licenses
```

按 `y` 接受所有许可协议。

#### 6. 验证安装

```bash
flutter doctor -v
```

应该看到：
```
[√] Android toolchain - develop for Android devices (Android SDK version 34.x.x)
    • Android SDK at C:\Users\...\AppData\Local\Android\Sdk
    • Platform android-34, build-tools 34.x.x
    • Java binary at: ...
    • Java version ...
```

---

### 方法 2：仅安装 Android 命令行工具（轻量，适合 CI/CD）

如果不想安装完整的 Android Studio：

#### 1. 下载命令行工具

- **官网**：https://developer.android.com/studio#command-line-tools-only
- **Windows 版本**：commandlinetools-win-11076708_latest.zip
- 文件大小：约 150 MB

#### 2. 解压并设置

```bash
# 创建 SDK 目录
mkdir C:\Android\Sdk

# 解压下载的 zip 到：
# C:\Android\Sdk\cmdline-tools\latest

# 设置环境变量
set ANDROID_HOME=C:\Android\Sdk
set PATH=%PATH%;%ANDROID_HOME%\cmdline-tools\latest\bin
```

#### 3. 安装 SDK 组件

```bash
cd C:\Android\Sdk\cmdline-tools\latest\bin

# 安装必需组件
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# 安装模拟器（可选）
sdkmanager "emulator" "system-images;android-34;google_apis;x86_64"
```

#### 4. 配置 Flutter

```bash
flutter config --android-sdk C:\Android\Sdk
flutter doctor --android-licenses
flutter doctor -v
```

---

## ✅ 安装后验证

### 1. 检查 Flutter Doctor

```bash
flutter doctor -v
```

期望输出：
```
[√] Flutter (Channel stable, 3.24.5, ...)
[√] Windows Version (...)
[√] Android toolchain - develop for Android devices (Android SDK version 34.x.x)
    • Android SDK at C:\Users\...\AppData\Local\Android\Sdk
    • Platform android-34, build-tools 34.x.x
    • ANDROID_HOME = C:\Users\...\AppData\Local\Android\Sdk
[√] Chrome - develop for the web
[√] Connected device (3 available)
```

### 2. 检查 ADB

```bash
adb version
```

应该看到：
```
Android Debug Bridge version 1.0.41
Version 34.x.x-xxx
```

### 3. 测试 APK 构建

```bash
cd E:\gemini_projects\exhibition-buyer-app
flutter build apk --release
```

成功后会看到：
```
✓ Built build\app\outputs\flutter-apk\app-release.apk (XX.X MB)
```

---

## 🧪 运行完整测试

安装完成后，立即运行预发布测试：

### 快速验证（推荐）
```bash
bash scripts/quick_verify.sh
```

这将执行：
1. 清理缓存
2. 获取依赖
3. 构建 Release APK
4. 在模拟器安装并测试
5. 生成测试报告

**预计时间**：5-8 分钟  
**输出**：`test_report_*.txt` 和 `logcat_*.log`

### 分步执行

```bash
# 1. 预发布检查（2分钟）
bash pre_release_check.sh

# 2. 集成测试（45秒）
bash scripts/run_integration_tests.sh quick

# 3. 模拟器测试（5分钟）
bash scripts/test_on_emulator.sh
```

---

## 🎯 创建和使用模拟器

### 查看可用模拟器

```bash
emulator -list-avds
```

### 创建新模拟器

```bash
# 列出可用的系统镜像
sdkmanager --list | grep "system-images"

# 下载 Android 13 (API 33) 镜像
sdkmanager "system-images;android-33;google_apis;x86_64"

# 创建模拟器
avdmanager create avd -n test_device -k "system-images;android-33;google_apis;x86_64" -d "pixel_5"
```

### 启动模拟器

```bash
# 启动模拟器
emulator -avd test_device

# 或使用测试脚本（自动创建）
bash scripts/test_on_emulator.sh
```

---

## ❓ 常见问题

### Q1: 提示 "ANDROID_HOME not set"

**解决**：
```bash
# 临时设置（当前终端）
export ANDROID_HOME="C:\Users\<用户名>\AppData\Local\Android\Sdk"

# 或永久设置环境变量（见上文）
```

### Q2: flutter doctor 仍显示 [X] Android toolchain

**可能原因**：
1. 环境变量未生效 - **重启终端或电脑**
2. SDK 路径错误 - 检查路径是否正确
3. 许可未接受 - 运行 `flutter doctor --android-licenses`

**解决**：
```bash
# 重启 Git Bash
exit
# 重新打开 Git Bash

# 再次检查
flutter doctor -v

# 手动指定路径
flutter config --android-sdk "C:\Users\Administrator\AppData\Local\Android\Sdk"
```

### Q3: 模拟器启动很慢或失败

**解决**：
1. 确保 BIOS 启用了虚拟化（Intel VT-x 或 AMD-V）
2. 关闭 Hyper-V（Windows 功能）
3. 使用 x86_64 镜像而不是 ARM

```bash
# 检查虚拟化
systeminfo | find "Virtualization"

# 应该显示：
# Hyper-V Requirements: A hypervisor has been detected...
```

### Q4: 构建 APK 时提示 Java 版本问题

**解决**：
```bash
# Android Studio 自带 JDK，使用它
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
```

---

## 📈 安装后的完整工作流

```bash
# 1. 验证环境
flutter doctor -v

# 2. 运行完整测试
bash scripts/quick_verify.sh

# 3. 查看报告
cat test_report_*.txt

# 4. 如果测试通过
bash pre_release_check.sh

# 5. 分发 APK
# 文件位置：build/app/outputs/flutter-apk/app-release.apk
```

---

## 💾 磁盘空间需求

- Android Studio：约 1.1 GB 下载 + 10-15 GB 安装
- Android SDK：约 5-8 GB
- 模拟器镜像：每个约 1-2 GB
- Flutter 构建缓存：约 1-3 GB

**总计**：约 20-30 GB

---

## 🆘 需要帮助？

1. 安装过程遇到问题，运行：
   ```bash
   flutter doctor -v > flutter_doctor_output.txt
   ```
   发送输出文件获取帮助

2. 查看详细测试文档：
   - `docs/PRE_RELEASE_WORKFLOW.md` - 完整测试流程
   - `docs/emulator_setup.md` - 模拟器详细配置
   - `docs/TESTING_STATUS.md` - 当前测试状态

3. 测试失败，查看：
   - `test_report_*.txt` - 测试报告
   - `logcat_*.log` - 应用日志

---

## ⏭️ 下一步

安装完成后：

1. ✅ 运行 `flutter doctor -v` 确认 Android toolchain 显示 [√]
2. ✅ 运行 `bash scripts/quick_verify.sh` 完整测试
3. ✅ 检查 `test_report_*.txt` 确认无错误
4. ✅ 分发 APK 给真机测试

**目标**：从"下载后才发现问题"变为"发布前捕获问题"！
