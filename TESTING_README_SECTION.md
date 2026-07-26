## 测试基础设施 🧪

**问题**：经历了 5 次版本更新，每次都是"下载后才发现不能用"

**解决方案**：建立完整的预发布测试体系，在真机测试前捕获所有问题

### 快速开始

查看 [`QUICK_START.md`](QUICK_START.md) 或 [`README_TESTING.md`](README_TESTING.md) 了解完整测试系统。

#### 一键测试（需要先安装 Android SDK）

```bash
# 完整验证（构建 + 模拟器测试）
bash scripts/quick_verify.sh

# 查看测试报告
cat test_report_*.txt
```

#### 首次设置

```bash
# 自动安装 Android SDK（轻量级）
bash scripts/install_android_sdk_cmdline.sh

# 或手动下载 Android Studio
# https://developer.android.com/studio
```

### 测试层级

| 层级 | 工具 | 时间 | 需要设备 |
|------|------|------|---------|
| L1: 静态检查 | `pre_release_check.sh` | 2分钟 | ❌ |
| L2: 集成测试 | `run_integration_tests.sh` | 45秒 | ❌ |
| L3: 模拟器测试 | `test_on_emulator.sh` | 5-8分钟 | ✅ 模拟器 |
| L4: 真机测试 | 手动测试清单 | 5-15分钟 | ✅ 真机 |

### 覆盖的历史问题

- ✅ "no host" 网络错误（v1.0.2）
- ✅ 启动挂起（v1.0.3）
- ✅ .env 加载失败（v1.0.4）
- ✅ GitHub Secrets 问题（v1.0.4）

### 主要文档

- 📖 [QUICK_START.md](QUICK_START.md) - 10分钟快速设置
- 📖 [README_TESTING.md](README_TESTING.md) - 测试文档中心
- 📖 [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md) - 完整部署总结
- 📖 [docs/PRE_RELEASE_WORKFLOW.md](docs/PRE_RELEASE_WORKFLOW.md) - 测试工作流程

### 可用脚本

```bash
# 环境检查
bash scripts/check_android_sdk.sh          # Android SDK 状态

# 快速验证
bash pre_release_check.sh                  # 预发布检查（2分钟）
bash scripts/run_integration_tests.sh quick # 集成测试（45秒）

# 完整测试
bash scripts/quick_verify.sh               # 一键完整验证（5-8分钟）

# 自动安装
bash scripts/install_android_sdk_cmdline.sh # 自动安装 Android SDK
```

---
