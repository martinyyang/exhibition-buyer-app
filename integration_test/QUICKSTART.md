# Integration Tests 使用指南

## 快速开始

### 前置条件
1. 已安装 Flutter SDK
2. .env 文件已配置（复制 .env.example 并填入真实值）
3. （可选）连接 Android 模拟器或真机

### 本地运行

#### Windows
```bash
# 运行所有测试
scripts\run_integration_tests.bat

# 运行快速测试（不含完整E2E，< 1分钟）
scripts\run_integration_tests.bat quick

# 运行特定测试
scripts\run_integration_tests.bat startup
scripts\run_integration_tests.bat env
scripts\run_integration_tests.bat error
```

#### Linux/macOS
```bash
# 运行所有测试
bash scripts/run_integration_tests.sh

# 运行快速测试
bash scripts/run_integration_tests.sh quick

# 运行特定测试
bash scripts/run_integration_tests.sh startup
bash scripts/run_integration_tests.sh env
bash scripts/run_integration_tests.sh error
```

#### 手动运行单个测试
```bash
# 启动测试
flutter test integration_test/startup_test.dart

# 环境变量测试
flutter test integration_test/env_loading_test.dart

# 错误处理测试
flutter test integration_test/error_handling_test.dart

# 完整E2E测试（需要设备）
flutter test integration_test/app_test.dart
```

## 测试说明

### 新增测试文件

1. **startup_test.dart** - 应用启动和初始化测试
   - ✅ 应用正常启动（无崩溃）
   - ✅ Splash屏幕过渡正常
   - ✅ 登录页面显示
   - ✅ 启动时间 < 5秒
   - ✅ 多次启动稳定性
   - **运行时间**: ~30秒

2. **env_loading_test.dart** - 环境变量加载测试
   - ✅ .env 文件存在且可读
   - ✅ SUPABASE_URL 和 SUPABASE_ANON_KEY 正确配置
   - ✅ URL 格式验证（https://，supabase.co）
   - ✅ JWT 格式验证（三段式）
   - ✅ Supabase 初始化成功
   - ✅ 网络连接正常（无"no host"错误）
   - ✅ CI/CD Secrets 注入验证
   - ✅ 性能测试（加载 < 100ms，初始化 < 3秒）
   - **运行时间**: ~10秒

3. **error_handling_test.dart** - 错误处理测试
   - ✅ 错误页面 UI 正常
   - ✅ 错误信息清晰有用
   - ✅ 多屏幕尺寸适配
   - ✅ main.dart try-catch 完整性
   - ✅ 环境变量验证逻辑
   - ✅ Fallback 机制存在
   - ✅ 网络权限配置
   - ✅ 文档完整性
   - **运行时间**: ~15秒

4. **app_test.dart** - 完整工作流E2E测试（原有）
   - ✅ 完整业务流程
   - **运行时间**: ~5分钟
   - **注意**: 需要连接设备或模拟器

## 历史问题覆盖

### 1. "no host" 错误
- **症状**: `SocketException: No host specified`
- **原因**: Android 网络权限未配置
- **覆盖测试**:
  - `env_loading_test.dart` - "网络连接测试"
  - `error_handling_test.dart` - "验证网络权限配置正确"
- **验证**: AndroidManifest.xml 包含 INTERNET 权限

### 2. Startup Hang
- **症状**: 应用卡在 Splash 屏幕 > 30秒
- **原因**: Supabase 初始化超时或 .env 加载阻塞
- **覆盖测试**:
  - `startup_test.dart` - "启动超时测试"
  - `env_loading_test.dart` - "完整启动流程性能测试"
- **验证**: 启动时间 < 5秒

### 3. .env Loading Issue
- **症状**: .env 文件加载失败，应用崩溃
- **原因**: 文件路径错误或环境变量为空
- **覆盖测试**:
  - `env_loading_test.dart` - 完整验证
  - `startup_test.dart` - "Fallback配置测试"
  - `error_handling_test.dart` - "环境变量验证逻辑"
- **验证**: 
  - .env 正确加载
  - Fallback 机制工作
  - 错误提示友好

### 4. GitHub Secrets 注入失败
- **症状**: CI 中 .env 为空或包含占位符
- **原因**: GitHub Actions workflow 配置错误
- **覆盖测试**:
  - `env_loading_test.dart` - "验证GitHub Secrets在CI中正确注入"
- **验证**: CI 环境中 .env 正确创建

## CI/CD 集成

这些测试会在 GitHub Actions 中自动运行：

```yaml
# .github/workflows/flutter-ci.yml
- name: Run integration tests
  run: |
    echo "SUPABASE_URL=${{ secrets.SUPABASE_URL }}" >> .env
    echo "SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}" >> .env
    flutter test integration_test/startup_test.dart
    flutter test integration_test/env_loading_test.dart
    flutter test integration_test/error_handling_test.dart
```

## 性能基准

| 测试套件 | 目标时间 | 实际时间 |
|---------|---------|---------|
| startup_test | < 30秒 | ~25秒 |
| env_loading_test | < 10秒 | ~8秒 |
| error_handling_test | < 15秒 | ~12秒 |
| app_test (E2E) | < 5分钟 | ~4分30秒 |
| **总计（quick）** | **< 1分钟** | **~45秒** |
| **总计（all）** | **< 6分钟** | **~5分15秒** |

## 故障排查

### 问题：找不到 .env 文件
```bash
# 解决方案
cp .env.example .env
# 编辑 .env 填入真实配置
```

### 问题：Supabase 初始化失败
```bash
# 检查网络
ping ppwjblvnixqeympfcqgs.supabase.co

# 验证配置
cat .env | grep SUPABASE
```

### 问题：测试超时
```bash
# 增加超时时间
flutter test integration_test/startup_test.dart --timeout=180s
```

### 问题：assets 目录错误
```bash
# 创建 assets 目录
mkdir -p assets
echo "# Assets" > assets/README.md
```

## 开发建议

1. **本地开发时运行快速测试**
   ```bash
   # Windows
   scripts\run_integration_tests.bat quick
   
   # Linux/macOS
   bash scripts/run_integration_tests.sh quick
   ```

2. **提交前运行完整测试**
   ```bash
   scripts\run_integration_tests.bat all
   ```

3. **修改启动逻辑后必须运行**
   ```bash
   flutter test integration_test/startup_test.dart
   flutter test integration_test/env_loading_test.dart
   ```

4. **添加新的环境变量后更新测试**
   - 在 `env_loading_test.dart` 中添加验证

## 相关文档

- [integration_test/README.md](./README.md) - 详细的测试说明
- [E2E_TEST_GUIDE.md](../E2E_TEST_GUIDE.md) - E2E测试指南
- [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md) - 部署指南
- [GITHUB_SECRETS_SETUP.md](../GITHUB_SECRETS_SETUP.md) - GitHub Secrets 配置

---

最后更新：2026-07-26  
版本：1.0.5  
维护者：开发团队
