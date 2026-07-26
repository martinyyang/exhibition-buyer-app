# GitHub Secrets 配置指南

## 问题说明

如果您从 GitHub Releases 下载的 APK 出现"应用初始化失败 - SUPABASE_URL not found in .env file"错误，说明 GitHub Actions 构建时没有正确配置 Secrets。

## 解决方案

### 步骤 1: 访问仓库设置

1. 打开您的 GitHub 仓库：https://github.com/martinyyang/exhibition-buyer-app
2. 点击 **Settings**（设置）标签
3. 在左侧菜单中找到 **Secrets and variables** > **Actions**

### 步骤 2: 添加 Secrets

点击 **New repository secret** 按钮，添加以下两个 secrets：

#### Secret 1: SUPABASE_URL
- **Name**: `SUPABASE_URL`
- **Secret**: `https://ppwjblvnixqeympfcqgs.supabase.co`

#### Secret 2: SUPABASE_ANON_KEY
- **Name**: `SUPABASE_ANON_KEY`
- **Secret**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2NDQ2MjQsImV4cCI6MjEwMDIyMDYyNH0.LhLw3KUTKrLXry6Qst5nLWKsGCxEewW5XW1Pc6QrzEE`

### 步骤 3: 重新构建

配置完 Secrets 后：
1. 进入 **Actions** 标签
2. 选择最新的 workflow run
3. 点击 **Re-run all jobs** 重新运行构建

或者，只需推送一个新的 commit，GitHub Actions 会自动构建新的 APK。

## 验证

配置正确后，GitHub Actions 构建日志中应该显示：
```
Creating .env file...
=== .env file contents ===
# Supabase项目配置

# Supabase项目URL
SUPABASE_URL=https://ppwjblvnixqeympfcqgs.supabase.co

# Supabase匿名公钥
SUPABASE_ANON_KEY=eyJhbGci...
=========================
✓ Secrets validated successfully
```

如果 Secrets 未配置，构建会失败并显示错误信息。

## 注意事项

⚠️ **安全提示**：
- SUPABASE_ANON_KEY 是匿名公钥，可以安全地公开
- 请勿将 SUPABASE_SERVICE_ROLE_KEY（服务密钥）添加到客户端应用或公开
- GitHub Secrets 是加密存储的，只在构建时使用

## 本地开发

本地开发时，请确保项目根目录有 `.env` 文件（该文件已在 `.gitignore` 中，不会提交到仓库）。
