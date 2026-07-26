# Exhibition Buyer App

展会买家应用 - 基于 Flutter 和 Supabase 构建的展会管理系统。

## 快速开始

### 环境要求

- Flutter SDK 3.0+
- Android Studio（用于 Android 开发）
- Android SDK（API Level 30+）

### 安装依赖

```bash
flutter pub get
```

### 配置环境变量

复制 `.env.example` 为 `.env` 并填写配置：

```bash
cp .env.example .env
```

编辑 `.env` 文件，配置 Supabase 连接信息。

### 运行应用

```bash
# 开发模式
flutter run

# 构建 Release APK
flutter build apk --release
```

## 测试

### Release APK 冒烟测试

在发布 APK 之前，执行冒烟测试确保基本质量：

#### 自动化冒烟测试（推荐）

一键运行完整的冒烟测试流程：

```bash
# 确保脚本可执行
chmod +x scripts/smoke_test.sh

# 运行冒烟测试
./scripts/smoke_test.sh
```

测试脚本会自动：
1. 检查 Flutter 和 ADB 环境
2. 检测 Android 设备或模拟器
3. 构建 Release APK
4. 安装 APK 到设备
5. 启动应用并监控 logcat
6. 检测崩溃、ANR、网络问题
7. 生成 PASS/FAIL 报告

#### 手动冒烟测试

参考快速检查清单（5分钟）：

1. 安装 APK 成功
2. 应用启动无崩溃（5秒内显示登录页面）
3. 登录功能正常
4. 核心页面可访问
5. 基础交互正常（按钮、滚动、跳转）

完整的手动测试清单：[docs/manual_test_checklist.md](docs/manual_test_checklist.md)

#### Flutter Integration Test

运行基于 Dart 的冒烟测试：

```bash
# 在连接的设备上运行
flutter test integration_test/smoke_test.dart
```

### 测试文档

- [冒烟测试指南](docs/smoke_test_guide.md) - 详细的测试流程和故障排查
- [手动测试清单](docs/manual_test_checklist.md) - 完整的手动测试步骤
- [模拟器设置指南](docs/emulator_setup.md) - Android 模拟器配置

### CI 自动化测试

GitHub Actions 会在以下情况自动运行冒烟测试：
- 推送 Git Tag (如 `v1.0.0`)
- 推送到 `release/**` 分支
- 手动触发工作流

只有冒烟测试通过后，才会创建 GitHub Release 并上传 APK。

配置文件：`.github/workflows/pre_release.yml`

## 已知问题修复历史

### v1.0.5 - .env 加载问题修复

**问题**：GitHub Actions 构建的 APK 在启动时显示"应用初始化失败"

**根本原因**：GitHub Actions 构建 APK 时未正确配置 Secrets，导致 .env 文件中的 SUPABASE_URL 和 SUPABASE_ANON_KEY 为空值。

**解决方案**：
- 增强 GitHub Actions workflow 的 .env 创建逻辑，添加验证步骤
- 如果 Secrets 未配置，构建会提前失败并显示清晰的错误信息
- 参考 [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md) 配置 GitHub Secrets

### v1.0.4 - 启动挂起问题修复

**问题**：应用启动后停留在白屏，无响应

**解决方案**：
- 添加 SplashScreen 显示加载状态
- 改进 router 的 redirect 逻辑处理 loading 状态
- 在 main.dart 中添加 try-catch 捕获初始化错误并显示错误页面

### v1.0.3 - "no host" 错误修复

**问题**：注册时出现 "no host" 网络错误

**解决方案**：
- 添加 Android 网络权限配置
- 增强环境变量验证逻辑
- 改进错误处理和用户提示

## 文档

- [模拟器设置指南](docs/emulator_setup.md)
- [GitHub Secrets 配置](GITHUB_SECRETS_SETUP.md)
- [部署指南](DEPLOYMENT_GUIDE.md)
- [E2E 测试指南](E2E_TEST_GUIDE.md)
- [Supabase 设置](SUPABASE_SETUP.md)

## 项目结构

```
lib/
├── core/           # 核心功能（路由、Provider等）
├── features/       # 功能模块
│   ├── auth/      # 认证
│   ├── events/    # 展会管理
│   ├── splash/    # 启动页
│   └── ...
└── main.dart      # 应用入口

scripts/
├── test_on_emulator.sh   # 模拟器自动化测试
└── quick_verify.sh       # 快速验证脚本

docs/
└── emulator_setup.md     # 模拟器配置指南
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## License

MIT
