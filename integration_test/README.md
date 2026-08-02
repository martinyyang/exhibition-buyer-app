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

### 5. `price_conversion_test.dart` - 价格转换E2E测试
验证价格转换和权限控制功能：
- ✅ 公式保存并正确转换价格
- ✅ 非团队创建者无法修改公式
- ✅ 公式跨会话持久化
- ✅ 公式历史记录功能

**前置条件：**

1. **数据库迁移必须执行**：
   - `supabase/migrations/20260802020000_add_team_creator_field.sql` - 添加 is_team_creator 字段
   - `supabase/migrations/20260802030000_restrict_formula_to_team_creator.sql` - 更新 RLS 策略

2. **测试账号必须存在**：
   - 团队创建者：`test@example.com` / `Test123456` (is_team_creator = true)
   - 普通成员：`remote2@example.com` / `Test123456` (is_team_creator = false)
   - 两个账号必须在同一团队

3. **Android 模拟器或真机**：
   - 集成测试不支持 Web 浏览器
   - 需要启动 Android 模拟器或连接真机

**运行命令：**
```bash
# 列出可用设备
flutter devices

# 在特定设备上运行
flutter test integration_test/price_conversion_test.dart -d <device_id>

# 或在 Android 模拟器上运行
flutter test integration_test/price_conversion_test.dart -d emulator-5554
```

**测试场景：**
1. 设置公式 RMB/6.75，验证预览计算（¥1000 → 148.15, ¥2000 → 296.30, ¥5000 → 740.74）
2. 非团队创建者登录，验证权限警告和禁用状态
3. 退出登录再登录，验证公式持久化
4. 设置新公式，验证历史记录功能

**故障排查：**
- **403 Forbidden 错误**：数据库迁移未执行
- **测试账号不存在**：需要创建测试账号并设置 is_team_creator 标志
- **无设备连接**：需要启动 Android 模拟器或连接真机

详细设置说明参见：[价格转换测试设置指南](#价格转换测试详细设置)

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

最后更新：2026-08-02
版本：1.1.0

## 价格转换测试详细设置

### 数据库迁移步骤

在运行 `price_conversion_test.dart` 之前，必须在 Supabase 控制台执行以下迁移：

**步骤 1：添加团队创建者字段**

1. 登录 Supabase 项目控制台
2. 进入 SQL Editor
3. 复制 `supabase/migrations/20260802020000_add_team_creator_field.sql` 内容
4. 执行 SQL

这个迁移会：
- 在 users 表添加 `is_team_creator` 字段
- 将每个团队的第一个用户标记为创建者

**步骤 2：更新 RLS 策略**

1. 在 SQL Editor 中
2. 复制 `supabase/migrations/20260802030000_restrict_formula_to_team_creator.sql` 内容
3. 执行 SQL

这个迁移会：
- 更新 exchange_settings 表的 INSERT 和 UPDATE 策略
- 只允许团队创建者修改公式
- 所有团队成员可以查看公式

### 测试账号创建步骤

**方法 1：通过应用注册**

1. 启动应用，注册第一个账号：`test@example.com`
2. 创建团队
3. 注册第二个账号：`remote2@example.com`
4. 使用第一个账号邀请第二个账号加入团队

**方法 2：通过 SQL 直接创建**

```sql
-- 验证账号和团队设置
SELECT 
  email, 
  is_team_creator, 
  team_id,
  created_at
FROM users 
WHERE email IN ('test@example.com', 'remote2@example.com')
ORDER BY created_at;

-- 如果需要手动设置团队创建者标志
UPDATE users 
SET is_team_creator = true 
WHERE email = 'test@example.com';

UPDATE users 
SET is_team_creator = false 
WHERE email = 'remote2@example.com';
```

### Android 模拟器设置

**安装 Android Studio**

1. 下载并安装 [Android Studio](https://developer.android.com/studio)
2. 打开 Android Studio
3. 进入 Tools → Device Manager
4. 创建虚拟设备（推荐：Pixel 5, API 33）
5. 启动模拟器

**通过命令行启动模拟器**

```bash
# 列出可用模拟器
flutter emulators

# 启动模拟器
flutter emulators --launch <emulator_name>

# 验证设备连接
flutter devices
```

### 运行测试的完整流程

```bash
# 1. 确保数据库迁移已执行
# 2. 确保测试账号已创建
# 3. 启动 Android 模拟器
flutter emulators --launch Pixel_5_API_33

# 4. 验证设备连接
flutter devices

# 5. 运行价格转换测试
flutter test integration_test/price_conversion_test.dart -d emulator-5554

# 或运行所有集成测试
flutter test integration_test/ -d emulator-5554
```

### CI/CD 集成

要在 GitHub Actions 中运行价格转换测试：

```yaml
- name: Setup Android Emulator
  uses: reactivecircus/android-emulator-runner@v2
  with:
    api-level: 33
    arch: x86_64
    profile: Nexus 6

- name: Run Integration Tests
  run: |
    flutter test integration_test/price_conversion_test.dart -d emulator-5554
```

**注意事项：**
- 确保 CI 环境中的数据库已执行迁移
- 测试账号需要预先创建
- 考虑使用测试专用的 Supabase 项目

### 常见问题

**Q: 为什么测试不能在 Web 浏览器上运行？**
A: Flutter 的集成测试框架不支持 Web 平台，必须使用 Android/iOS 模拟器或真机。

**Q: 如何验证数据库迁移是否成功？**
A: 运行以下 SQL：
```sql
-- 检查字段是否存在
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'is_team_creator';

-- 检查 RLS 策略
SELECT policyname, permissive, roles, cmd 
FROM pg_policies 
WHERE tablename = 'exchange_settings';
```

**Q: 测试失败提示 403 Forbidden 怎么办？**
A: 这表示 RLS 策略迁移未执行或未生效。请：
1. 检查 Supabase 控制台中的 RLS 策略
2. 重新执行迁移 SQL
3. 验证测试账号的 is_team_creator 标志

**Q: 如何在本地快速验证功能？**
A: 无需运行完整测试，可以：
1. 启动应用：`flutter run -d emulator-5554`
2. 用 `test@example.com` 登录
3. 手动测试公式设置和权限控制功能

