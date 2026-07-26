# Android 模拟器自动化测试使用指南

## 概述

本项目提供了完整的 Android 模拟器自动化测试方案，可以自动检测常见问题并生成详细报告。

## 快速开始

### 一键验证（推荐）

从构建到测试一键完成：

```bash
bash scripts/quick_verify.sh
```

这会执行完整的验证流程：
1. 清理构建缓存
2. 获取依赖
3. 构建 Release APK
4. 在模拟器中自动化测试

### 单独测试

如果已经有构建好的 APK：

```bash
bash scripts/test_on_emulator.sh
```

## 测试内容

自动化测试会检测以下问题：

### 1. 致命错误检测
- ❌ "no host" 网络错误
- ❌ UnknownHostException
- ❌ "应用初始化失败" 错误
- ❌ Supabase 初始化失败
- ❌ .env 文件缺失或配置错误
- ❌ 应用崩溃（FATAL EXCEPTION）
- ❌ ANR（Application Not Responding）

### 2. 启动流程验证
- ✅ .env 文件加载
- ✅ Supabase 初始化
- ✅ 应用正常启动（30秒内）
- ✅ 无挂起或黑屏

### 3. 配置验证
- ⚠️ 是否使用 fallback 配置
- ⚠️ 环境变量完整性

## 测试输出

### 测试报告

每次测试会生成 `test_report_YYYYMMDD_HHMMSS.txt` 报告文件，包含：

```
===============================================
Android 模拟器测试报告
===============================================
测试时间: 2026-07-26 10:30:45
APK: build/app/outputs/flutter-apk/app-release.apk
包名: com.example.exhibition_buyer_app

设备信息:
  Android 版本: 11
  API Level: 30
  设备型号: sdk_gphone_x86_64

===============================================
测试结果
===============================================
✓ 未发现致命错误
⚠ 发现 1 个警告:
  - Using fallback configuration (missing .env file)

===============================================
关键日志片段
===============================================

### 应用初始化 ###
[日志内容...]

===============================================
```

### Logcat 日志

完整的 logcat 输出保存在 `logcat_emulator_test_YYYYMMDD_HHMMSS.log`。

### 控制台输出

测试过程中会实时显示彩色进度信息：

```
[INFO] 检查必要工具...
[SUCCESS] 所有必要工具已安装
[INFO] 检查 APK 文件...
[SUCCESS] 找到 APK: build/app/outputs/flutter-apk/app-release.apk (15M)
[INFO] 启动模拟器 'exhibition_test_emulator'...
[SUCCESS] 模拟器启动完成（耗时 45s）
[INFO] 安装 APK...
[SUCCESS] APK 安装成功
[INFO] 监控 logcat 输出（30s）...
[SUCCESS] 日志捕获完成
[SUCCESS] ✓ 测试通过 - 未发现致命错误
```

## 模拟器管理

### 自动创建

测试脚本会自动检测并创建模拟器：
- 名称：`exhibition_test_emulator`
- API Level: 30 (Android 11)
- 设备类型：Pixel 4
- RAM: 4096 MB
- Storage: 2048 MB

### 手动创建

如果需要自定义配置，参考 [docs/emulator_setup.md](../docs/emulator_setup.md)。

### 模拟器状态

测试脚本会保留模拟器运行，方便手动测试：

```bash
# 查看运行的设备
adb devices

# 手动启动应用
adb shell am start -n com.example.exhibition_buyer_app/.MainActivity

# 查看实时日志
adb logcat | grep flutter

# 关闭模拟器
adb emu kill
```

## 常见问题

### 测试失败："no host" 错误

**原因**：.env 文件缺失或 SUPABASE_URL/SUPABASE_ANON_KEY 配置错误

**解决**：
1. 检查项目根目录是否存在 `.env` 文件
2. 确认 `.env` 文件包含正确的 Supabase 配置
3. 重新构建 APK：`flutter build apk`

### 测试失败：应用初始化失败

**原因**：Supabase 配置无效或网络连接问题

**解决**：
1. 验证 Supabase URL 和 ANON_KEY 是否正确
2. 检查网络连接
3. 查看完整 logcat 日志了解详细错误

### 测试失败：启动超时

**原因**：模拟器性能不足或应用卡在某个环节

**解决**：
1. 增加模拟器 RAM（编辑 AVD 配置）
2. 启用硬件加速（HAXM/KVM）
3. 检查 logcat 日志定位卡住的位置

### 警告：使用 fallback 配置

**说明**：应用使用了硬编码的 fallback 配置，而不是 .env 文件

**影响**：开发环境可以正常工作，但生产环境可能使用错误的配置

**解决**：
1. 确保 `.env` 文件存在且配置正确
2. 重新构建 APK
3. 如果是 CI/CD 构建，检查 GitHub Secrets 配置（参考 [GITHUB_SECRETS_SETUP.md](../GITHUB_SECRETS_SETUP.md)）

## CI/CD 集成

### GitHub Actions

可以将模拟器测试集成到 CI/CD 流程中：

```yaml
- name: Run Emulator Tests
  run: |
    # 启动模拟器
    echo "no" | avdmanager create avd --force --name test --package "system-images;android-30;google_apis;x86_64"
    emulator -avd test -no-window -no-audio &
    
    # 运行测试
    bash scripts/test_on_emulator.sh
```

**注意**：GitHub Actions 的 macOS runner 支持硬件加速，推荐使用 `macos-latest`。

## 最佳实践

### 发布前验证

每次发布新版本前运行快速验证：

```bash
# 1. 确保代码已提交
git status

# 2. 运行完整验证
bash scripts/quick_verify.sh

# 3. 如果通过，创建 release tag
git tag -a v1.0.6 -m "Release v1.0.6"
git push origin v1.0.6
```

### 手动冒烟测试

自动化测试通过后，建议进行手动冒烟测试：

1. **注册流程**：注册新用户账号
2. **登录流程**：使用新账号登录
3. **主要功能**：浏览展会列表、查看详情
4. **退出登录**：确认可以正常退出

模拟器保持运行状态，可以直接在模拟器中手动测试。

### 问题追踪

如果测试发现问题：
1. 保存测试报告和 logcat 日志
2. 在 Issues 中创建 Bug 报告，附上日志
3. 修复后重新运行测试验证

## 相关文档

- [模拟器配置指南](../docs/emulator_setup.md)
- [GitHub Secrets 配置](../GITHUB_SECRETS_SETUP.md)
- [部署指南](../DEPLOYMENT_GUIDE.md)
- [项目完成报告](../PROJECT_COMPLETION_REPORT.md)

## 贡献

如果发现测试脚本的问题或有改进建议，欢迎提交 PR！

测试脚本位置：
- `scripts/test_on_emulator.sh` - 主测试脚本
- `scripts/quick_verify.sh` - 快速验证脚本
