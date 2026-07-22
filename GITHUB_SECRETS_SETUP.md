# GitHub Secrets 配置指南

## 问题说明

之前 GitHub Actions 打包失败是因为缺少 Supabase 环境变量配置。现在代码已经修复，使用 `flutter_dotenv` 来加载环境变量。

## 需要配置的 Secrets

在 GitHub 仓库中配置以下 secrets：

### 1. 进入 Settings > Secrets and variables > Actions

### 2. 添加以下 Repository secrets：

#### SUPABASE_URL
```
https://ppwjblvnixqeympfcqgs.supabase.co
```

#### SUPABASE_ANON_KEY
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2NDQ2MjQsImV4cCI6MjEwMDIyMDYyNH0.LhLw3KUTKrLXry6Qst5nLWKsGCxEewW5XW1Pc6QrzEE
```

## 配置步骤

1. 打开你的 GitHub 仓库
2. 点击 **Settings** 标签
3. 在左侧菜单找到 **Secrets and variables** > **Actions**
4. 点击 **New repository secret**
5. 添加第一个 secret：
   - Name: `SUPABASE_URL`
   - Secret: (复制上面的 URL)
6. 点击 **Add secret**
7. 重复步骤 4-6，添加 `SUPABASE_ANON_KEY`

## 修改内容总结

### 1. 代码修改
- ✅ `pubspec.yaml` - 添加了 `flutter_dotenv` 依赖
- ✅ `lib/main.dart` - 从环境变量加载 Supabase 配置，移除了硬编码
- ✅ `.github/workflows/ci.yml` - 在 build 步骤中注入环境变量

### 2. 安全改进
- ❌ **之前**: Supabase 密钥直接硬编码在代码中
- ✅ **现在**: 使用环境变量，通过 GitHub Secrets 安全注入

## 验证

配置完成后，推送代码到 GitHub，GitHub Actions 应该能够：
1. ✅ 通过测试
2. ✅ 成功构建 Android APK
3. ✅ 成功构建 Web 应用

## 下次推送时的步骤

```bash
git add .
git commit -m "fix: 使用环境变量配置 Supabase，修复 CI/CD 构建"
git push
```

推送后查看 Actions 标签页，确认构建成功。
