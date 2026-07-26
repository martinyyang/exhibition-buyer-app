# Release APK 冒烟测试指南

本文档介绍如何执行 Release APK 的冒烟测试，确保发布前应用的基本质量。

## 目录

1. [什么是冒烟测试](#什么是冒烟测试)
2. [测试环境准备](#测试环境准备)
3. [自动化冒烟测试](#自动化冒烟测试)
4. [手动冒烟测试](#手动冒烟测试)
5. [CI 集成](#ci-集成)
6. [故障排查](#故障排查)

---

## 什么是冒烟测试

冒烟测试（Smoke Testing）是一种快速的基础测试，用于验证软件的核心功能是否正常工作。对于 Release APK，冒烟测试的目标是：

- **验证应用能启动** - 不会崩溃或卡住
- **验证核心流程可用** - 登录、主要功能入口正常
- **验证环境配置正确** - .env 文件、网络连接正常
- **验证基础交互正常** - 页面跳转、按钮点击、表单输入

**冒烟测试不是**：
- 全面的功能测试
- 性能测试
- 安全测试

冒烟测试应该在 5-15 分钟内完成，快速发现阻塞性问题。

---

## 测试环境准备

### 1. 软件要求

- **Flutter SDK**: 3.24.5 或更高版本
- **Android SDK**: API Level 26+ (Android 8.0+)
- **ADB**: Android Debug Bridge
- **Java**: JDK 17

验证安装：

```bash
flutter --version
adb --version
java -version
```

### 2. 硬件要求

选择以下任一选项：

#### 选项 A：使用 Android 模拟器

```bash
# 查看可用的模拟器
flutter emulators

# 启动模拟器
flutter emulators --launch <emulator_id>

# 或使用 Android Studio 启动模拟器
```

**推荐模拟器配置**：
- 设备：Pixel 4 或更新
- API Level：30 (Android 11)
- RAM：2048 MB
- 存储：4 GB

#### 选项 B：使用真机

1. 在手机上启用开发者选项
2. 启用 USB 调试
3. 连接手机到电脑
4. 验证连接：

```bash
adb devices
# 应该显示你的设备
```

### 3. 环境配置

确保项目根目录有 `.env` 文件：

```bash
# .env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

**注意**：不要将 `.env` 文件提交到版本控制。

---

## 自动化冒烟测试

### 方法 1：使用 Shell 脚本（推荐）

自动化脚本会构建 APK、安装、启动并验证基础功能。

```bash
# 进入项目目录
cd /path/to/exhibition-buyer-app

# 确保脚本可执行
chmod +x scripts/smoke_test.sh

# 运行冒烟测试
./scripts/smoke_test.sh
```

**脚本执行流程**：
1. 检查 Flutter、ADB 环境
2. 检查设备连接
3. 构建 Release APK
4. 安装 APK 到设备
5. 启动应用
6. 监控 logcat 检测崩溃、ANR
7. 验证应用进程正在运行
8. 检查网络请求能力
9. 生成测试报告

**预期输出**：

```
[INFO] 步骤 1/7: 检查测试环境...
✓ Flutter 和 ADB 已安装
[INFO] 步骤 2/7: 检查 Android 模拟器...
✓ 检测到设备: emulator-5554
✓ 设备状态正常
[INFO] 步骤 3/7: 构建 Release APK...
✓ Release APK 构建成功 (耗时: 45s)
[INFO] 步骤 4/7: 安装 Release APK 到设备...
✓ APK 安装成功 (耗时: 3s)
[INFO] 步骤 5/7: 启动应用并监控启动过程...
[INFO] 等待应用启动 (15秒超时)...
✓ 应用启动无崩溃
✓ 应用启动无卡顿 (ANR)
✓ .env 配置加载正常
[INFO] 步骤 6/7: 检查应用进程状态...
✓ 应用进程正在运行
[INFO] 步骤 7/7: 检查网络请求能力...
✓ 应用可以发起网络请求
===============================================
冒烟测试完成
===============================================
通过测试: 10
失败测试: 0
-----------------------------------------------
PASS: Flutter 和 ADB 已安装
PASS: 检测到设备: emulator-5554
PASS: 设备状态正常
PASS: Release APK 构建成功 (耗时: 45s)
PASS: APK 安装成功 (耗时: 3s)
PASS: 应用启动无崩溃
PASS: 应用启动无卡顿 (ANR)
PASS: .env 配置加载正常
PASS: 应用进程正在运行
PASS: 应用可以发起网络请求
-----------------------------------------------
✅ 冒烟测试全部通过！Release APK 可以发布
```

### 方法 2：使用 Flutter Integration Test

运行 Dart 编写的集成测试：

```bash
# 运行冒烟测试
flutter test integration_test/smoke_test.dart

# 或在真机/模拟器上运行
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/smoke_test.dart
```

**优点**：
- 可以测试 UI 交互
- 可以验证状态管理
- 跨平台（iOS、Android、Web）

**缺点**：
- 需要编写测试代码
- 执行时间较长

---

## 手动冒烟测试

当自动化测试不可用或需要验证自动化未覆盖的场景时，执行手动测试。

### 快速 5 分钟检查清单

1. **安装 APK**
   - [ ] 从 APK 文件安装成功
   - [ ] 应用图标显示正常

2. **首次启动**
   - [ ] 点击应用图标
   - [ ] 5 秒内显示登录页面
   - [ ] 无崩溃或黑屏

3. **登录测试**
   - [ ] 输入测试账号
   - [ ] 点击登录按钮
   - [ ] 登录成功或显示清晰的错误提示

4. **核心功能入口**
   - [ ] 进入场次选择页面
   - [ ] 进入摊位列表
   - [ ] 进入照片网格

5. **基础交互**
   - [ ] 点击按钮有反馈
   - [ ] 列表可以滚动
   - [ ] 页面跳转正常

### 完整测试清单

参考 [manual_test_checklist.md](./manual_test_checklist.md) 进行全面的手动测试。

---

## CI 集成

### GitHub Actions 配置

项目已配置自动化 CI 流程：`.github/workflows/pre_release.yml`

**触发条件**：
- 推送 Git Tag（如 `v1.0.0`）
- 推送到 `release/**` 分支
- 手动触发（workflow_dispatch）

**工作流程**：

1. **smoke-test 任务**
   - 设置 Flutter 和 Android 环境
   - 启动 Android 模拟器
   - 运行冒烟测试脚本
   - 测试失败时上传日志和 APK

2. **build-and-release 任务**（仅在冒烟测试通过后执行）
   - 构建 Release APK
   - 创建 GitHub Release
   - 上传 APK 到 Release
   - 在 Release 描述中标注"冒烟测试已通过"

### 本地测试 CI 配置

在推送代码前，本地验证 CI 配置：

```bash
# 安装 act (GitHub Actions 本地运行工具)
# macOS
brew install act

# Linux
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# 本地运行工作流
act push -j smoke-test
```

### 配置 GitHub Secrets

确保在 GitHub 仓库中配置以下 Secrets：

1. 进入 GitHub 仓库
2. 点击 **Settings** > **Secrets and variables** > **Actions**
3. 添加 Secrets：
   - `SUPABASE_URL`: Supabase 项目 URL
   - `SUPABASE_ANON_KEY`: Supabase 匿名密钥

---

## 故障排查

### 问题 1：ADB 找不到设备

**症状**：
```
[ERROR] 未检测到 Android 设备或模拟器
```

**解决方法**：
1. 验证设备连接：
   ```bash
   adb devices
   ```
2. 如果显示 "offline" 或 "unauthorized"：
   ```bash
   adb kill-server
   adb start-server
   adb devices
   ```
3. 真机：检查 USB 调试是否启用，允许计算机访问
4. 模拟器：重启模拟器

### 问题 2：APK 构建失败

**症状**：
```
[ERROR] Release APK 构建失败
```

**解决方法**：
1. 检查 Flutter 版本：
   ```bash
   flutter --version
   flutter upgrade
   ```
2. 清理构建缓存：
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```
3. 检查 `.env` 文件是否存在
4. 查看详细错误日志

### 问题 3：应用启动崩溃

**症状**：
```
[ERROR] 应用启动时崩溃 (FATAL EXCEPTION)
```

**解决方法**：
1. 查看完整 logcat 日志：
   ```bash
   adb logcat | grep -A 20 "FATAL EXCEPTION"
   ```
2. 常见原因：
   - .env 文件未包含在 APK 中
   - Supabase 配置错误
   - 网络权限未声明
3. 验证 `pubspec.yaml` 包含：
   ```yaml
   flutter:
     assets:
       - .env
   ```

### 问题 4：应用启动卡住 (ANR)

**症状**：
```
[ERROR] 应用启动时卡住 (ANR)
```

**解决方法**：
1. 检查是否有阻塞主线程的操作
2. 查看 ANR 日志：
   ```bash
   adb logcat | grep -A 20 "ANR in"
   ```
3. 常见原因：
   - 主线程执行网络请求
   - Supabase 初始化阻塞
   - 大量数据库查询

### 问题 5：.env 配置加载失败

**症状**：
```
[WARN] .env 加载可能存在问题
```

**解决方法**：
1. 确认 `.env` 文件在项目根目录
2. 确认 `pubspec.yaml` 包含 `.env` 资源
3. 确认代码中正确加载：
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';

   void main() async {
     await dotenv.load(fileName: ".env");
     runApp(MyApp());
   }
   ```
4. 验证 Secrets 配置正确（CI 环境）

### 问题 6：CI 测试超时

**症状**：
GitHub Actions 显示 "The job running on runner has exceeded the maximum execution time of X minutes"

**解决方法**：
1. 增加超时时间（`.github/workflows/pre_release.yml`）：
   ```yaml
   - name: Run Smoke Test
     run: ./scripts/smoke_test.sh
     timeout-minutes: 30  # 增加超时时间
   ```
2. 优化测试脚本，减少等待时间
3. 使用更快的模拟器配置

---

## 最佳实践

### 1. 发布前检查清单

在每次发布前执行：

- [ ] 运行自动化冒烟测试：`./scripts/smoke_test.sh`
- [ ] 执行快速手动测试（5 分钟）
- [ ] 在至少一台真机上安装测试
- [ ] 验证版本号正确（`pubspec.yaml`）
- [ ] 验证 CHANGELOG 已更新
- [ ] 验证 .env 配置指向生产环境

### 2. 冒烟测试频率

- **每次构建 Release APK**：必须运行
- **每次合并到主分支**：可选，建议运行
- **每天自动构建**：可选，用于持续集成

### 3. 测试数据准备

为冒烟测试准备专用测试账号：

```
邮箱: smoketest@example.com
密码: SmokeTest123!
```

确保测试账号：
- 有稳定的测试数据
- 不会影响生产数据
- 权限完整（买手和远程端角色）

### 4. 持续改进

根据实际问题更新测试用例：

1. 发现新的启动问题 → 添加到自动化测试
2. 手动测试发现的问题 → 考虑自动化
3. 定期回顾测试覆盖率

---

## 相关文档

- [手动测试清单](./manual_test_checklist.md) - 完整的手动测试步骤
- [集成测试文档](../integration_test/README.md) - 完整功能的 E2E 测试
- [CI/CD 配置](../.github/workflows/) - GitHub Actions 工作流

---

## 反馈与改进

如果您在使用冒烟测试过程中遇到问题或有改进建议，请：

1. 提交 Issue：[GitHub Issues](https://github.com/your-repo/exhibition-buyer-app/issues)
2. 更新本文档（Pull Request）
3. 联系团队成员

---

**最后更新**：2026-07-26  
**维护者**：开发团队
