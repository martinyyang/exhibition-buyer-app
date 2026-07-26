# Integration Test 集成测试指南

本目录包含针对 Exhibition Buyer App 的集成测试，覆盖应用启动、环境变量加载、错误处理等关键场景。

## 测试文件说明

### 1. `startup_test.dart` - 应用启动测试
验证应用启动流程和初始化：
- ✅ 应用正常启动（无崩溃）
- ✅ Splash屏幕正常显示和过渡
- ✅ 路由正常工作（登录页面显示）
- ✅ 启动时间 < 5秒（避免hang）
- ✅ 多次启动稳定性

**运行命令：**
```bash
flutter test integration_test/startup_test.dart
```

### 2. `env_loading_test.dart` - 环境变量加载测试
验证 .env 文件加载和配置：
- ✅ .env 文件存在且可读
- ✅ SUPABASE_URL 和 SUPABASE_ANON_KEY 存在且非空
- ✅ 环境变量格式正确（URL格式、JWT格式）
- ✅ Supabase 客户端初始化成功
- ✅ 网络连接正常（无"no host"错误）
- ✅ CI/CD 环境中 GitHub Secrets 正确注入
- ✅ 性能：加载时间 < 100ms，初始化时间 < 3秒

**运行命令：**
```bash
flutter test integration_test/env_loading_test.dart
```

### 3. `error_handling_test.dart` - 错误处理测试
验证错误场景的处理：
- ✅ 错误页面UI正常显示
- ✅ 错误信息清晰且有用
- ✅ 提供恢复步骤指导
- ✅ main.dart 包含完整的 try-catch
- ✅ 环境变量验证逻辑
- ✅ Fallback 机制存在
- ✅ 网络权限配置正确
- ✅ 文档文件完整

**运行命令：**
```bash
flutter test integration_test/error_handling_test.dart
```

### 4. `app_test.dart` - 完整工作流E2E测试
验证完整的用户工作流（原有测试）：
- ✅ 买手登录-创建场次-拍照-标注流程
- ✅ 场次切换和数据隔离
- ✅ 公式换算和历史记录
- ✅ 买手小组协作
- ✅ 红色警告标记逻辑
- ✅ 响应式布局
- ✅ 供应商信息管理
- ✅ 旗子编号顺序

**运行命令：**
```bash
flutter test integration_test/app_test.dart
```

## 运行所有集成测试

### 本地模拟器
```bash
# 运行所有集成测试
flutter test integration_test

# 运行特定测试文件
flutter test integration_test/startup_test.dart

# 在真机/模拟器上运行（带UI）
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/startup_test.dart
```

### CI/CD 环境
集成测试会在 GitHub Actions 中自动运行，需要配置以下 Secrets：
- `SUPABASE_URL`: Supabase 项目URL
- `SUPABASE_ANON_KEY`: Supabase 匿名密钥

GitHub Actions 工作流会：
1. 从 Secrets 创建 .env 文件
2. 启动 Android 模拟器
3. 运行所有集成测试
4. 上传测试报告

## 历史问题覆盖

这些测试专门覆盖了以下历史问题：

### 1. "no host" 错误（网络权限问题）
- **问题**：Android 应用启动时报 `SocketException: No host specified`
- **覆盖测试**：
  - `env_loading_test.dart` - "网络连接测试"
  - `error_handling_test.dart` - "验证网络权限配置正确"
- **验证**：AndroidManifest.xml 包含 INTERNET 权限

### 2. Startup Hang（启动挂起）
- **问题**：应用启动时卡在 Splash 屏幕，超过 30 秒无响应
- **覆盖测试**：
  - `startup_test.dart` - "启动超时测试"
  - `env_loading_test.dart` - "完整启动流程性能测试"
- **验证**：启动时间 < 5 秒

### 3. .env Loading Issue（环境变量加载失败）
- **问题**：.env 文件加载失败或变量为空，导致应用崩溃
- **覆盖测试**：
  - `env_loading_test.dart` - 完整的环境变量验证
  - `startup_test.dart` - "Fallback配置测试"
  - `error_handling_test.dart` - "环境变量验证逻辑"
- **验证**：
  - .env 文件正确加载
  - 环境变量格式正确
  - Fallback 机制工作

### 4. GitHub Secrets 注入失败
- **问题**：CI/CD 中 GitHub Secrets 未正确注入到 .env
- **覆盖测试**：
  - `env_loading_test.dart` - "验证GitHub Secrets在CI中正确注入"
- **验证**：CI 环境中 .env 文件正确创建

## 测试性能指标

所有测试应该快速且可靠：

| 测试套件 | 预期时间 | 关键指标 |
|---------|---------|---------|
| startup_test.dart | < 30秒 | 启动时间 < 5秒 |
| env_loading_test.dart | < 10秒 | 加载时间 < 100ms |
| error_handling_test.dart | < 15秒 | UI渲染正常 |
| app_test.dart | < 5分钟 | 完整工作流 |

**总计：< 6分钟**

## 故障排查

### 测试失败：找不到 .env 文件
```bash
# 确保 .env 文件存在
cp .env.example .env
# 填入正确的 Supabase 配置
```

### 测试失败：Supabase 初始化错误
```bash
# 检查网络连接
ping ppwjblvnixqeympfcqgs.supabase.co

# 验证 .env 配置
cat .env | grep SUPABASE
```

### 测试超时
```bash
# 增加超时时间
flutter test integration_test/startup_test.dart --timeout=120s

# 检查模拟器性能
flutter devices
```

### CI/CD 中测试失败
1. 检查 GitHub Secrets 是否配置
2. 查看 CI 日志中的 .env 文件创建步骤
3. 验证模拟器是否成功启动

## 添加新测试

创建新的集成测试时，请遵循以下模板：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('你的测试组名称', () {
    testWidgets('你的测试名称', (tester) async {
      // 1. 准备测试环境
      // 2. 执行操作
      // 3. 验证结果
      // 4. 清理
    });
  });
}
```

## 最佳实践

1. **快速失败**：测试应该在遇到问题时立即失败，提供清晰的错误信息
2. **独立运行**：每个测试应该独立，不依赖其他测试的状态
3. **清理资源**：测试完成后清理创建的数据和状态
4. **有意义的断言**：使用 `reason` 参数解释为什么断言会失败
5. **性能监控**：记录关键操作的时间，确保应用性能

## 参考文档

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md) - 部署指南
- [E2E_TEST_GUIDE.md](../E2E_TEST_GUIDE.md) - E2E测试指南
- [GITHUB_SECRETS_SETUP.md](../GITHUB_SECRETS_SETUP.md) - GitHub Secrets 配置

## 维护说明

- **更新频率**：每次修改启动流程或环境变量加载逻辑时更新
- **负责人**：开发团队
- **审查周期**：每个 Sprint 审查测试覆盖率
- **性能基准**：每月检查测试执行时间，确保 < 6分钟

---

最后更新：2026-07-26
版本：1.0.5
