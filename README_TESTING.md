# 📱 Exhibition Buyer App - 测试指南

> **从"下载后才发现问题"到"发布前自动验证"**

---

## 🎯 快速导航

| 你想做什么？ | 运行这个 | 耗时 |
|------------|---------|------|
| 🚀 首次设置 | 查看 [`QUICK_START.md`](QUICK_START.md) | 10-30分钟 |
| ✅ 快速检查 | `bash pre_release_check.sh` | 2分钟 |
| 🧪 运行测试 | `bash scripts/run_integration_tests.sh quick` | 45秒 |
| 📦 完整验证 | `bash scripts/quick_verify.sh` | 5-8分钟 |
| 🔍 检查SDK | `bash scripts/check_android_sdk.sh` | 10秒 |

---

## 📊 测试体系概览

```
┌─────────────────────────────────────────────┐
│  L1: 静态检查 (2分钟, 无需设备)              │
│  ✓ Flutter环境 ✓ 依赖 ✓ .env ✓ 权限        │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│  L2: 集成测试 (45秒, 无需设备)               │
│  ✓ 启动 ✓ 环境变量 ✓ 错误处理               │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│  L3: 模拟器测试 (5-8分钟)                    │
│  ✓ APK构建 ✓ 启动检测 ✓ 错误捕获            │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│  L4: 真机测试 (手动)                         │
│  ✓ 实际用户场景 ✓ 硬件兼容性                │
└─────────────────────────────────────────────┘
```

---

## 🚦 测试状态

运行以下命令查看当前状态：

```bash
bash scripts/check_android_sdk.sh
```

### 正常状态（全部就绪）
```
✓ ANDROID_HOME 已设置
✓ adb 已安装
✓ Java 已安装
✓ emulator 已安装
✓ Flutter doctor 通过
```

### 需要安装 Android SDK
```
✗ Android SDK 未找到
```
→ 查看 [`QUICK_START.md`](QUICK_START.md) 或 [`docs/ANDROID_SDK_SETUP.md`](docs/ANDROID_SDK_SETUP.md)

---

## 📖 主要文档

### 快速入门
- [**QUICK_START.md**](QUICK_START.md) - 10分钟快速设置
- [**DEPLOYMENT_SUMMARY.md**](DEPLOYMENT_SUMMARY.md) - 完整部署总结

### 测试流程
- [**docs/PRE_RELEASE_WORKFLOW.md**](docs/PRE_RELEASE_WORKFLOW.md) - 发布前测试工作流
- [**docs/TESTING_STATUS.md**](docs/TESTING_STATUS.md) - 当前测试状态
- [**integration_test/QUICKSTART.md**](integration_test/QUICKSTART.md) - 集成测试快速上手

### 环境设置
- [**docs/ANDROID_SDK_SETUP.md**](docs/ANDROID_SDK_SETUP.md) - Android SDK 详细安装
- [**docs/emulator_setup.md**](docs/emulator_setup.md) - 模拟器配置
- [**docs/EMULATOR_TEST_GUIDE.md**](docs/EMULATOR_TEST_GUIDE.md) - 模拟器测试指南

### 专项测试
- [**docs/smoke_test_guide.md**](docs/smoke_test_guide.md) - 冒烟测试
- [**docs/manual_test_checklist.md**](docs/manual_test_checklist.md) - 手动测试清单
- [**docs/release_process.md**](docs/release_process.md) - 发布流程

---

## 🛠️ 可用脚本

### 预发布检查
```bash
# Windows
pre_release_check.bat

# Unix/Linux/macOS
bash pre_release_check.sh
```

### 集成测试
```bash
# 快速测试（推荐）
bash scripts/run_integration_tests.sh quick

# 完整测试
bash scripts/run_integration_tests.sh all
```

### 模拟器测试
```bash
# 一键完整验证（构建 + 测试）
bash scripts/quick_verify.sh

# 仅测试已有 APK
bash scripts/test_on_emulator.sh
```

### 环境检查
```bash
# Android SDK 状态
bash scripts/check_android_sdk.sh

# Flutter 环境
flutter doctor -v
```

---

## 🎓 使用场景

### 场景 1: 日常开发
```bash
# 修改代码后
flutter analyze
bash scripts/run_integration_tests.sh quick
```

### 场景 2: 发布前
```bash
# 完整验证
bash scripts/quick_verify.sh

# 查看结果
cat test_report_*.txt
```

### 场景 3: CI/CD
```bash
# 推送 tag 触发自动测试
git tag v1.0.6
git push origin v1.0.6
```

---

## 🐛 历史问题覆盖

本测试体系覆盖了最近 5 个版本的所有问题：

| 版本 | 问题 | 测试覆盖 |
|-----|------|---------|
| v1.0.4 | .env 加载失败 | ✅ 环境变量验证 |
| v1.0.3 | 启动挂起 | ✅ 30秒超时检测 |
| v1.0.2 | "no host" 网络错误 | ✅ 权限检查 + Logcat |
| v1.0.1 | GitHub Secrets 问题 | ✅ CI 环境验证 |

---

## 📈 效果对比

### 之前 ❌
```
修改代码 → 构建 → 发布 → 下载 → 发现问题
  ↑                                      |
  └──────────────────────────────────────┘
           重复 5 次 😫
```

### 现在 ✅
```
修改代码 → 本地测试(8分钟) → 通过 ✓ → 发布 → 成功 🎉
```

---

## 💡 最佳实践

### ✅ 推荐

- 每次 commit 前运行集成测试
- 每次发布前运行完整验证
- 定期清理构建缓存 (`flutter clean`)
- 保存测试报告以便追溯

### ❌ 避免

- 跳过测试直接发布
- 忽略 flutter analyze 警告
- 在未验证的情况下修改 .env
- 不查看测试报告就分发 APK

---

## 🆘 需要帮助？

1. **查看文档**：按优先级检查上面列出的文档
2. **运行诊断**：
   ```bash
   bash scripts/check_android_sdk.sh > diagnostics.txt
   flutter doctor -v >> diagnostics.txt
   ```
3. **检查日志**：
   - 测试报告：`test_report_*.txt`
   - 应用日志：`logcat_*.log`

---

## 🎯 成功标准

**可以发布的条件**：
- ✅ `flutter analyze` - 0 errors
- ✅ `pre_release_check.sh` - 全部通过
- ✅ `run_integration_tests.sh` - 全部通过
- ✅ `quick_verify.sh` - 测试报告无错误
- ✅ APK 大小 10-100MB

**满足以上 → 可以安全分发给真机测试** 🚀

---

## 📞 快速命令参考

```bash
# 首次设置
bash scripts/install_android_sdk_cmdline.sh  # 自动安装 SDK

# 日常检查
flutter analyze                              # 静态分析
bash pre_release_check.sh                    # 预发布检查

# 完整测试
bash scripts/quick_verify.sh                 # 一键验证

# 查看结果
cat test_report_*.txt                        # 测试报告
cat logcat_*.log                            # 应用日志

# 环境验证
bash scripts/check_android_sdk.sh           # SDK 状态
flutter doctor -v                           # Flutter 环境
```

---

**🎉 现在开始享受"一次发布就成功"的快乐吧！**
