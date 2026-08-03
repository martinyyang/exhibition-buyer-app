# Cloudflare Pages 部署指南

本指南详细说明如何将 Flutter Web 应用部署到 Cloudflare Pages，以及环境变量配置方法。

## 为什么选择 Cloudflare Pages？

- **全球 CDN**：自动分发到 Cloudflare 全球边缘节点，提供极快的访问速度
- **免费额度**：无限带宽、无限请求次数（合理使用范围内）
- **自动部署**：推送到 GitHub 后自动触发构建和部署
- **中国访问优化**：Cloudflare CDN 在中国有良好的连通性
- **HTTPS 支持**：自动提供 SSL 证书
- **零配置服务器**：无需管理服务器，专注代码开发

## 前置要求

- Cloudflare 账号（免费注册：https://dash.cloudflare.com/sign-up）
- GitHub 仓库（项目代码已推送）
- Supabase 项目的 URL 和 ANON_KEY

## 步骤 1：创建 Cloudflare Pages 项目

### 1.1 登录 Cloudflare Dashboard

访问 https://dash.cloudflare.com/ 并登录您的账号。

### 1.2 连接 GitHub 仓库

1. 点击左侧菜单的 **"Workers & Pages"**
2. 点击 **"Create application"** 按钮
3. 选择 **"Pages"** 标签页
4. 点击 **"Connect to Git"**
5. 选择 **GitHub**，授权 Cloudflare 访问您的仓库
6. 选择 `exhibition-buyer-app` 仓库

### 1.3 配置构建设置

在构建配置页面，填写以下信息：

- **Project name**: `exhibition-buyer-app`（或自定义名称）
- **Production branch**: `master`
- **Framework preset**: 选择 `None`（手动配置）
- **Build command**: 
  ```bash
  flutter/bin/flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY --dart-define=SUPABASE_PROXY_URL=$SUPABASE_PROXY_URL
  ```
- **Build output directory**: `build/web`
- **Root directory**: `/`（留空或填 `/`）

## 步骤 2：配置环境变量（关键步骤）

⚠️ **重要**：Cloudflare Pages **不支持 `.env` 文件**，必须在控制台配置环境变量。

### 2.1 添加环境变量

在项目设置页面：

1. 进入 **Settings** → **Environment variables**
2. 点击 **"Add variable"** 添加以下变量：

#### Production 环境变量

| Variable name | Value | 说明 |
|--------------|-------|------|
| `SUPABASE_URL` | `https://ppwjblvnixqeympfcqgs.supabase.co` | Supabase 项目 URL |
| `SUPABASE_ANON_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` | Supabase 匿名公钥 |
| `SUPABASE_PROXY_URL` | （留空或填代理 URL） | Cloudflare Workers 代理 URL（可选） |

3. 环境选择 **Production**
4. 点击 **"Save"**

### 2.2 环境变量说明

- **SUPABASE_URL**：必填，Supabase 项目的直连 URL
- **SUPABASE_ANON_KEY**：必填，从 Supabase Dashboard 获取
- **SUPABASE_PROXY_URL**：可选，如果配置了 Cloudflare Workers 代理，填入代理 URL；否则留空

## 步骤 3：部署应用

### 3.1 首次部署

配置完成后，点击 **"Save and Deploy"**，Cloudflare Pages 会自动：

1. 克隆 GitHub 仓库
2. 安装 Flutter SDK
3. 执行构建命令（注入环境变量）
4. 部署到全球 CDN

### 3.2 查看部署状态

1. 在 **Deployments** 页面可以看到构建进度
2. 构建日志会显示详细的执行过程
3. 构建成功后会显示部署的 URL

### 3.3 访问应用

部署成功后，您会得到一个 URL：

```
https://exhibition-buyer-app.pages.dev
```

或者自定义域名（如果配置了）。

## 步骤 4：自动部署设置

### 4.1 Git 集成

Cloudflare Pages 默认会监听 GitHub 仓库的 `master` 分支：

- 每次推送到 `master` 分支时自动触发部署
- Pull Request 会创建预览部署
- 可以在 **Settings** → **Builds & deployments** 中配置

### 4.2 手动触发部署

如果需要手动触发部署：

1. 进入 **Deployments** 页面
2. 点击 **"Retry deployment"**（重新部署）
3. 或者点击 **"Create custom deployment"**（自定义部署）

## 工作原理：编译时环境变量

### 本地开发 vs Cloudflare Pages

项目代码已做兼容处理，支持两种环境：

#### 本地开发（使用 `.env` 文件）

```dart
// lib/main.dart
await dotenv.load(fileName: '.env');
supabaseUrl = dotenv.env['SUPABASE_URL'];
```

运行命令：
```bash
flutter run -d chrome
```

#### Cloudflare Pages 部署（使用编译时变量）

```dart
// lib/main.dart
const webSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
if (webSupabaseUrl.isNotEmpty) {
  supabaseUrl = webSupabaseUrl;
}
```

构建命令（Cloudflare Pages 自动执行）：
```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=SUPABASE_PROXY_URL=$SUPABASE_PROXY_URL
```

### 代码自动检测逻辑

```dart
void main() async {
  // 1. 尝试读取编译时环境变量（Cloudflare Pages）
  const webSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  
  if (webSupabaseUrl.isNotEmpty) {
    // Cloudflare Pages 部署环境
    print('✓ Using compile-time environment variables (Cloudflare Pages)');
    supabaseUrl = webSupabaseUrl;
  } else {
    // 本地开发环境
    await dotenv.load(fileName: '.env');
    print('✓ Loaded .env file successfully (local development)');
    supabaseUrl = dotenv.env['SUPABASE_URL'];
  }
}
```

## 常见问题

### Q1: 部署后显示 "SUPABASE_URL not found"

**原因**：环境变量未正确配置或构建命令缺少 `--dart-define`。

**解决**：
1. 检查 **Settings** → **Environment variables** 是否已添加
2. 确认构建命令包含 `--dart-define=SUPABASE_URL=$SUPABASE_URL`
3. 重新部署（Retry deployment）

### Q2: 环境变量修改后不生效

**原因**：修改环境变量后需要重新部署。

**解决**：
1. 进入 **Deployments** 页面
2. 点击最新部署的 **"Retry deployment"**
3. 或者推送一个新的提交触发部署

### Q3: 构建超时或失败

**原因**：Flutter SDK 下载或构建过程超时。

**解决**：
1. 检查构建日志中的错误信息
2. 确认 `flutter build web` 命令能在本地正常执行
3. 检查依赖是否正常（`flutter pub get`）
4. 如果是首次构建，可能需要更长时间

### Q4: 如何更新 Supabase 密钥？

**步骤**：
1. 进入 **Settings** → **Environment variables**
2. 找到 `SUPABASE_ANON_KEY` 变量
3. 点击 **"Edit"**，更新值
4. 点击 **"Save"**
5. 重新部署

## 性能优化

### 缓存设置

Cloudflare Pages 自动缓存静态资源：

- HTML：缓存 5 分钟
- JS/CSS：缓存 24 小时（版本化文件名）
- 图片/字体：缓存 7 天

无需额外配置。

### 构建时间优化

首次构建可能需要 5-10 分钟（下载 Flutter SDK），后续构建通常在 2-3 分钟内完成。

## 自定义域名（可选）

### 添加自定义域名

1. 进入 **Custom domains** 页面
2. 点击 **"Set up a custom domain"**
3. 输入您的域名（如：`app.example.com`）
4. 按照提示在 DNS 服务商添加 CNAME 记录
5. 等待 DNS 传播（通常 < 5 分钟）

### DNS 配置示例

在您的 DNS 服务商添加：

```
Type: CNAME
Name: app
Value: exhibition-buyer-app.pages.dev
```

## 监控与分析

### 访问统计

Cloudflare Pages 提供基础的访问统计：

1. 进入 **Analytics** 页面
2. 查看请求数、带宽使用量、地域分布

### 构建历史

1. 进入 **Deployments** 页面
2. 查看所有部署记录、构建日志
3. 可以回滚到任意历史版本

## 团队协作

### 添加团队成员

1. 进入 **Settings** → **Access**
2. 点击 **"Add member"**
3. 输入邮箱并设置权限
4. 成员可以查看部署、查看日志、重新部署

### 预览部署（Preview Deployments）

Pull Request 会自动创建预览部署：

- 每个 PR 都有独立的预览 URL
- 合并前可以测试新功能
- 不影响生产环境

## 成本

### 免费额度

Cloudflare Pages 免费计划包括：

- ✅ 无限带宽
- ✅ 无限请求次数
- ✅ 每月 500 次构建
- ✅ 每次构建 20 分钟超时
- ✅ 1 个并发构建

对于中小型项目完全够用。

### 付费计划

如果需要更多构建次数或并发构建，可升级到 **Pages Pro**（$20/月）。

## 安全建议

1. **保护环境变量**：确保 `SUPABASE_ANON_KEY` 只配置在 Cloudflare Pages 后台，不要提交到 Git
2. **启用 RLS**：Supabase 的 Row Level Security 已启用，保护数据安全
3. **定期更新密钥**：定期轮换 Supabase 密钥
4. **监控异常访问**：在 Cloudflare Analytics 中关注异常流量

## 故障排除检查清单

部署失败时，按顺序检查：

- [ ] GitHub 仓库是否已连接
- [ ] 构建命令是否正确
- [ ] 环境变量是否已添加（`SUPABASE_URL`, `SUPABASE_ANON_KEY`）
- [ ] 构建输出目录是否为 `build/web`
- [ ] 本地 `flutter build web --release` 是否能成功
- [ ] 构建日志中是否有明确的错误信息

## 相关文档

- [Cloudflare Workers 代理设置](./CLOUDFLARE_PROXY_SETUP.md) - 优化中国网络访问
- [Supabase 配置指南](../README.md#setup) - 数据库和认证设置
- [环境变量配置](./.env.example) - 本地开发环境变量模板

## 支持

如有问题，请：
1. 查看 Cloudflare Pages 文档：https://developers.cloudflare.com/pages/
2. 查看构建日志排查错误
3. 提交 GitHub Issue
4. 联系团队技术负责人
