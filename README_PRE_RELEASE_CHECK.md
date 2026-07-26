# 预发布验证脚本使用指南

## 概述

预发布验证脚本用于在真机测试前自动检查Flutter应用的构建环境、配置和构建结果，确保APK能够成功构建且配置正确。

## 文件说明

- `pre_release_check.sh` - Bash版本（适用于Git Bash、WSL、Linux、macOS）
- `pre_release_check.bat` - Windows批处理版本（适用于Windows CMD）

## 使用方法

### Windows环境

**方式1：使用批处理文件（推荐）**
```cmd
pre_release_check.bat
```

**方式2：使用Git Bash**
```bash
bash pre_release_check.sh
```

### Linux/macOS环境

```bash
chmod +x pre_release_check.sh
./pre_release_check.sh
```

## 检查项目

### 1. Flutter环境检查
- 运行 `flutter doctor` 验证Flutter SDK完整性
- 显示详细的环境信息

### 2. 依赖完整性检查
- 运行 `flutter pub get` 确保所有依赖已正确下载
- 验证 pubspec.yaml 中的依赖可用

### 3. 静态代码分析
- 运行 `flutter analyze` 检查代码质量
- 确保没有语法错误或严重警告

### 4. 配置文件验证
- 检查 `.env` 文件是否存在
- 验证必需的环境变量：
  - `SUPABASE_URL` - 必须是有效的HTTPS URL
  - `SUPABASE_ANON_KEY` - 必须是有效的密钥（长度>50字符）

### 5. Android配置验证
- 检查 `AndroidManifest.xml` 包含 `INTERNET` 权限
- 确保应用能够访问网络

### 6. 版本号验证
- 检查 `pubspec.yaml` 中的版本号格式
- 要求格式：`major.minor.patch+buildNumber`（例如：1.0.5+5）

### 7. Assets配置检查
- 验证 `.env` 文件已在 `pubspec.yaml` 的 assets 列表中

### 8. Release构建测试
- 执行 `flutter build apk --release` 构建生产版本
- 验证构建过程无错误

### 9. APK文件验证
- 检查APK文件是否生成
- 验证文件大小合理（10MB - 100MB）
- 提供APK路径和大小信息

## 输出报告

脚本执行完成后会显示：

```
========================================
验证报告
========================================
✓ 通过: 12
✗ 失败: 0
⚠ 警告: 1

APK路径: build\app\outputs\flutter-apk\app-release.apk
APK大小: 23MB
版本号: 1.0.5+5

========================================
🎉 所有检查通过，可以进行真机测试！
========================================
```

## 常见问题修复建议

### .env文件未配置

**问题：**
```
✗ 失败: .env 文件不存在
```

**解决方案：**
1. 复制 `.env.example` 为 `.env`
2. 填入真实的Supabase配置：
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=eyJhbGc...（你的实际密钥）
   ```

### 缺少INTERNET权限

**问题：**
```
✗ 失败: AndroidManifest.xml 缺少 INTERNET 权限
```

**解决方案：**
在 `android/app/src/main/AndroidManifest.xml` 的 `<manifest>` 标签内添加：
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### 版本号格式错误

**问题：**
```
✗ 失败: 版本号格式错误: 1.0.0
```

**解决方案：**
修改 `pubspec.yaml` 中的版本号为：
```yaml
version: 1.0.0+1
```

### 依赖下载失败

**问题：**
```
✗ 失败: 依赖下载失败
```

**解决方案：**
1. 检查网络连接
2. 删除 `pubspec.lock` 和 `~/.pub-cache` 缓存
3. 重新运行 `flutter pub get`

### 代码分析错误

**问题：**
```
✗ 失败: 代码分析发现错误
```

**解决方案：**
1. 查看具体的错误信息
2. 修复代码中的语法错误或类型错误
3. 运行 `flutter analyze` 单独测试

### APK构建失败

**问题：**
```
✗ 失败: APK构建失败
```

**解决方案：**
1. 检查构建日志中的具体错误
2. 常见原因：
   - Gradle版本不兼容
   - NDK配置问题
   - 代码签名问题
3. 尝试清理后重新构建：
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

## 最佳实践

1. **每次发布前运行**：在准备真机测试或发布前，总是运行此脚本
2. **CI/CD集成**：可以将此脚本集成到CI/CD流程中
3. **版本管理**：每次发布前确保版本号已正确递增
4. **配置安全**：不要将 `.env` 文件提交到代码仓库

## 下一步

验证通过后，你可以：

1. **安装到真机测试**：
   ```bash
   flutter install
   # 或手动安装APK
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

2. **进行功能测试**：
   - 登录/注册流程
   - 网络请求（Supabase连接）
   - 图片上传
   - 数据同步

3. **性能测试**：
   - 启动速度
   - 页面切换流畅度
   - 内存占用

4. **发布到应用商店**：
   - Google Play Store
   - 华为应用市场
   - 其他第三方应用市场
