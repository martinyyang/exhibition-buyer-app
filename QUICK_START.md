# 🚀 快速开始 - 从零到可测试

本指南帮助你在 10 分钟内建立完整的测试环境。

---

## 📋 前置条件

- ✅ Flutter 已安装（你已经有了）
- ✅ Git Bash 或类似终端
- ⚠️ Android SDK **未安装**（我们来解决这个）

---

## ⚡ 快速路径（推荐）

### 选项 A：自动安装（最快，10-15 分钟）

```bash
# 运行自动安装脚本（轻量级 CLI 版本）
bash scripts/install_android_sdk_cmdline.sh
```

这将自动：
1. 下载 Android 命令行工具（150 MB）
2. 安装必需的 SDK 组件
3. 配置环境变量
4. 设置 Flutter

**注意**：需要稳定的网络连接

---

### 选项 B：手动安装（更可靠，20-30 分钟）

#### 1. 下载 Android Studio

访问：https://developer.android.com/studio

或直接下载（Windows）：
```
https://redirector.gvt1.com/edgedl/android/studio/install/2024.2.1.12/android-studio-2024.2.1.12-windows.exe
```

#### 2. 安装

- 双击运行安装程序
- 选择 **Standard** 安装
- 等待下载 SDK 组件（约 5-10 分钟）

#### 3. 配置 Flutter

```bash
# 接受 Android 许可
flutter doctor --android-licenses

# 验证安装
flutter doctor -v
```

---

## ✅ 验证安装

运行检查脚本：

```bash
bash scripts/check_android_sdk.sh
```

**期望输出**：
```
✓ ANDROID_HOME 已设置
✓ adb 已安装
✓ Java 已安装
✓ emulator 已安装
[√] Android toolchain - develop for Android devices
```

---

## 🧪 运行首次测试

### 1. 快速验证（2 分钟）

```bash
bash pre_release_check.sh
```

**检查**：
- Flutter 环境
- 依赖完整性
- .env 配置
- APK 构建

---

### 2. 集成测试（45 秒）

```bash
bash scripts/run_integration_tests.sh quick
```

**测试**：
- 应用启动
- 环境变量加载
- 错误处理

---

### 3. 完整模拟器测试（5-8 分钟）

```bash
bash scripts/quick_verify.sh
```

**完整流程**：
1. 清理缓存
2. 构建 Release APK
3. 启动模拟器
4. 安装并启动应用
5. 检测常见错误
6. 生成测试报告

**输出文件**：
- `test_report_*.txt` - 测试结果
- `logcat_*.log` - 应用日志

---

## 📊 查看测试结果

### 成功示例

```
========================================
模拟器测试完成
========================================

✓ 模拟器启动成功
✓ APK 安装成功
✓ 应用启动成功
✓ 未检测到严重错误

错误检查结果:
  ✓ 无 "no host" 错误
  ✓ 无启动挂起
  ✓ 无应用崩溃
  ✓ 无 ANR 无响应
  ✓ .env 配置正常

总结: 测试通过 ✓
```

---

### 失败示例

```
========================================
模拟器测试完成
========================================

✗ 检测到问题:
  [错误] 发现 "no host" 错误 (2 次)
  [警告] 应用启动时间较长 (8 秒)

查看详细日志:
  logcat_20260726_123456.log:245
  logcat_20260726_123456.log:312

建议修复:
  1. 检查 AndroidManifest.xml 网络权限
  2. 优化启动流程
```

---

## 🎯 日常使用

### 每次代码更改后

```bash
# 静态检查
flutter analyze

# 快速测试
bash scripts/run_integration_tests.sh quick
```

---

### 每次发布前

```bash
# 完整验证
bash scripts/quick_verify.sh

# 检查报告
cat test_report_*.txt

# 如果通过，分发 APK
# 文件位置: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🆘 遇到问题？

### 问题：flutter doctor 显示 Android toolchain [X]

**解决**：
```bash
# 重启终端
exit
# 重新打开 Git Bash

# 检查环境变量
echo $ANDROID_HOME

# 手动设置（如果为空）
export ANDROID_HOME="/c/Users/$USER/AppData/Local/Android/Sdk"
flutter config --android-sdk "$ANDROID_HOME"
```

---

### 问题：模拟器启动失败

**解决**：
```bash
# 检查可用模拟器
emulator -list-avds

# 如果没有，创建一个
avdmanager create avd -n test_device -k "system-images;android-34;google_apis;x86_64"

# 手动启动
emulator -avd test_device
```

---

### 问题：APK 构建失败

**解决**：
```bash
# 清理缓存
flutter clean
flutter pub get

# 重新构建
flutter build apk --release
```

---

## 📚 详细文档

需要更多信息？查看：

- **完整工作流**：`docs/PRE_RELEASE_WORKFLOW.md`
- **Android SDK 安装**：`docs/ANDROID_SDK_SETUP.md`
- **测试状态**：`docs/TESTING_STATUS.md`
- **故障排查**：`docs/EMULATOR_TEST_GUIDE.md`

---

## 💡 小贴士

### 加速构建

```bash
# 清理旧的构建缓存（每周一次）
flutter clean

# 使用 ABI 分割减小 APK 大小
flutter build apk --split-per-abi
```

---

### 多次测试

```bash
# 保留测试报告
mkdir test_reports
mv test_report_*.txt test_reports/
mv logcat_*.log test_reports/
```

---

### CI/CD 自动化

```bash
# 推送 tag 触发自动测试
git tag v1.0.6
git push origin v1.0.6

# GitHub Actions 会自动运行测试并创建 Release
```

---

## ✨ 成功标志

当你看到这些，说明一切就绪：

- ✅ `flutter doctor` 全绿
- ✅ `bash scripts/check_android_sdk.sh` 全部通过
- ✅ `bash scripts/quick_verify.sh` 测试通过
- ✅ `test_report_*.txt` 显示无错误

**你已经准备好了！再也不会"下载后才发现不能用"了！** 🎉

---

## 🎯 下一步

1. 安装 Android SDK（选择上面的选项 A 或 B）
2. 运行 `bash scripts/check_android_sdk.sh` 验证
3. 运行 `bash scripts/quick_verify.sh` 首次测试
4. 查看 `test_report_*.txt` 确认无错误
5. 开始自信地发布 APK！

**预计总时间**：10-30 分钟（取决于网络速度）
