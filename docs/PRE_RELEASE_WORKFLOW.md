# 📋 发布前测试工作流程

**目标**：在真机测试前捕获所有已知问题，避免重复"下载后才发现不能用"的情况。

---

## 🎯 快速开始（推荐流程）

### 第一步：预发布检查（2分钟）
运行自动化检查脚本，验证构建环境和配置：

```bash
# Windows
pre_release_check.bat

# Git Bash / Linux / macOS
bash pre_release_check.sh
```

**检查内容**：
- ✅ Flutter 环境完整性
- ✅ .env 配置正确性
- ✅ Android 权限配置
- ✅ Release APK 构建成功
- ✅ APK 文件大小合理

**输出**：彩色报告 + APK 路径

---

### 第二步：快速集成测试（45秒）
运行单元/集成测试，无需真实设备：

```bash
# Windows
scripts\run_integration_tests.bat quick

# Git Bash / Linux / macOS
bash scripts/run_integration_tests.sh quick
```

**测试覆盖**：
- ✅ 应用启动流程（< 5秒启动时间）
- ✅ .env 文件加载和验证
- ✅ Supabase 初始化
- ✅ 错误处理和用户提示

---

### 第三步：模拟器冒烟测试（5-8分钟）
在 Android 模拟器上安装并运行 Release APK：

```bash
# 一键完整流程（构建 + 测试）
bash scripts/quick_verify.sh

# 或单独测试已有 APK
bash scripts/test_on_emulator.sh
```

**自动检测**：
- ✅ "no host" 网络错误
- ✅ 启动挂起（30秒超时）
- ✅ 应用崩溃 (FATAL EXCEPTION)
- ✅ ANR 无响应
- ✅ .env 加载失败
- ✅ Supabase 初始化失败

**输出**：
- 测试报告：`test_report_YYYYMMDD_HHMMSS.txt`
- Logcat 日志：`logcat_YYYYMMDD_HHMMSS.log`

---

### 第四步：手动验证（可选，5分钟）
参考完整清单进行快速手动检查：

```bash
# 打开手动测试清单
docs/manual_test_checklist.md
```

**核心验证项**：
- 注册/登录流程
- 主要功能页面加载
- 网络请求正常
- 图片上传功能

---

## 📊 三层测试体系

| 层级 | 工具 | 时间 | 需要设备 | 何时运行 |
|------|------|------|---------|---------|
| **L1: 静态检查** | `pre_release_check.bat` | 2分钟 | ❌ | 每次构建前 |
| **L2: 集成测试** | `run_integration_tests.bat` | 45秒 | ❌ | 每次代码更改 |
| **L3: 冒烟测试** | `test_on_emulator.sh` | 5-8分钟 | ✅ 模拟器 | 发布前 |
| **L4: 手动测试** | `manual_test_checklist.md` | 5-15分钟 | ✅ 真机 | 发布前 |

---

## 🚀 CI/CD 自动化

每次推送 Git Tag 时自动运行完整测试：

```bash
# 触发 CI 预发布工作流
git tag v1.0.6
git push origin v1.0.6
```

**CI 会自动**：
1. 在云端模拟器运行冒烟测试
2. 构建 Release APK
3. 创建 GitHub Release
4. 上传 APK 并标注"冒烟测试已通过"

配置文件：`.github/workflows/pre_release.yml`

---

## 🔍 历史问题覆盖

根据最近 5 次版本更新的问题，测试已覆盖：

| 问题 | Commit | 解决方案 | 自动检测 |
|------|--------|---------|---------|
| "no host" 错误 | 72b1c58 | 添加网络权限 | ✅ 权限检查 + Logcat |
| 启动挂起 | 74e25fd | Splash + 错误处理 | ✅ 30秒超时检测 |
| .env 加载失败 | 873a034 | Fallback 配置 | ✅ 环境变量验证 |
| GitHub Secrets 问题 | 30669b5 | Secrets 验证 | ✅ CI 环境检测 |

---

## 📁 相关文档

- **模拟器设置指南**：`docs/emulator_setup.md`
- **冒烟测试指南**：`docs/smoke_test_guide.md`
- **手动测试清单**：`docs/manual_test_checklist.md`
- **发布流程**：`docs/release_process.md`
- **集成测试快速开始**：`integration_test/QUICKSTART.md`

---

## ⚠️ 常见问题

### Q1: 模拟器启动失败？
```bash
# 检查可用模拟器
emulator -list-avds

# 手动创建测试模拟器
avdmanager create avd -n test_device -k "system-images;android-30;google_apis;x86_64"
```

参考：`docs/emulator_setup.md`

### Q2: 冒烟测试报告"no host"错误？
检查 `android/app/src/main/AndroidManifest.xml` 是否包含：
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### Q3: .env 验证失败？
确保项目根目录有 `.env` 文件，包含：
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Q4: APK 太大（> 100MB）？
可能包含了调试符号或未压缩资源。运行：
```bash
flutter build apk --release --split-per-abi
```

---

## 🎉 成功标准

**可以发布给真机测试的条件**：
- ✅ `pre_release_check.bat` 全部通过
- ✅ `run_integration_tests.bat quick` 全部通过
- ✅ `test_on_emulator.sh` 测试报告无错误
- ✅ APK 大小在 10-100MB 之间
- ✅ 手动测试核心流程（登录、主功能）正常

满足以上条件后，APK 可以安全分发给真机测试用户。

---

## 📞 需要帮助？

- 查看详细日志：`logcat_*.log`
- 查看测试报告：`test_report_*.txt`
- 参考故障排查：`docs/EMULATOR_TEST_GUIDE.md`
