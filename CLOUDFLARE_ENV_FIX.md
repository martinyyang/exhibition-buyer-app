# ✅ Cloudflare Pages 环境变量修复完成

## 问题描述

**症状**：两个手机（有/无 VPN）访问 https://exhibition-buyer-app.pages.dev 都报错 "应用初始化失败"

**根因**：Cloudflare Pages Production 环境变量未配置，导致 Flutter 编译时 `String.fromEnvironment()` 返回空字符串，应用走到 `dotenv.load()` 分支但生产环境没有 `.env` 文件，抛出异常。

## 修复操作

### 1. 诊断（2026-08-06 09:42）

通过 Cloudflare API 查询项目配置，发现：
```json
"deployment_configs": {
  "production": {
    "env_vars": null  // ❌ 环境变量为空
  }
}
```

### 2. 配置环境变量（2026-08-06 09:50）

使用 Cloudflare API 添加 Production 环境变量：
```bash
SUPABASE_URL = https://ppwjblvnixqeympfcqgs.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_PROXY_URL = （空字符串，未启用代理）
```

**API 调用**：
```bash
curl -X PATCH "https://api.cloudflare.com/client/v4/accounts/{account_id}/pages/projects/exhibition-buyer-app" \
  -H "Authorization: Bearer {token}" \
  -d '{"deployment_configs": {"production": {"env_vars": {...}}}}'
```

### 3. 触发重新部署（2026-08-06 09:53）

推送空提交触发 Cloudflare Pages 重新构建：
```bash
git commit --allow-empty -m "chore: trigger redeploy with environment variables configured"
git push origin main
```

**Commit**: 4b8d8fc1f5ddcfe878d8a9d06b74129e03aba163

### 4. 验证部署（2026-08-06 09:58）

- ✅ GitHub Actions 构建成功
- ✅ Cloudflare Pages Production 部署成功
- ✅ 站点可访问：https://exhibition-buyer-app.pages.dev

## 验证步骤（请在手机测试）

### 有 VPN 的手机
1. 访问：https://exhibition-buyer-app.pages.dev
2. 应该能看到登录页面，不再报"应用初始化失败"
3. 可以正常登录和使用

### 无 VPN 的手机
1. 访问：https://exhibition-buyer-app.pages.dev
2. 应该能看到登录页面（Cloudflare CDN 在中国可访问）
3. 登录后如果 Supabase 连接慢，是正常的（可选配置 SUPABASE_PROXY_URL）

## 技术说明

### Flutter 编译时环境变量工作原理

```dart
// lib/main.dart
const webSupabaseUrl = String.fromEnvironment('SUPABASE_URL');

if (webSupabaseUrl.isNotEmpty) {
  // ✓ 使用编译时常量（Cloudflare Pages 现在走这个分支）
  supabaseUrl = webSupabaseUrl;
} else {
  // ✗ 尝试加载 .env 文件（生产环境会失败）
  await dotenv.load(fileName: '.env');
}
```

**关键点**：
- `String.fromEnvironment()` 是编译时常量，不是运行时读取
- 必须在构建命令中通过 `--dart-define` 注入
- Cloudflare Pages 构建命令已包含 `--dart-define=SUPABASE_URL=$SUPABASE_URL`
- 但如果环境变量未配置，`$SUPABASE_URL` 就是空字符串

### Cloudflare Pages 构建命令

```bash
git clone --depth 1 -b 3.24.5 https://github.com/flutter/flutter.git $HOME/flutter && \
export PATH="$HOME/flutter/bin:$PATH" && \
flutter doctor && \
flutter build web --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=SUPABASE_PROXY_URL=$SUPABASE_PROXY_URL
```

## 后续优化建议

### 1. 配置 Supabase 代理（可选，优化中国访问）

如果无 VPN 的手机访问 Supabase 很慢，可以配置 Cloudflare Workers 代理：

1. 创建 Cloudflare Worker 代理（参考 `docs/CLOUDFLARE_PROXY_SETUP.md`）
2. 在 Cloudflare Pages 环境变量中设置：
   ```
   SUPABASE_PROXY_URL = https://your-worker.workers.dev
   ```
3. 触发重新部署

### 2. 监控部署状态

使用 Cloudflare API 或 Wrangler CLI：
```bash
wrangler pages deployment list --project-name=exhibition-buyer-app
```

### 3. 环境变量管理

**生产环境变量存储位置**：
- Cloudflare Dashboard: Workers & Pages → exhibition-buyer-app → Settings → Environment variables
- 本地 `.env.cloudflare` 文件（仅存储 API Token，不存储 Supabase 密钥）

**安全提醒**：
- `SUPABASE_ANON_KEY` 是公开密钥，可以放心存储在 Cloudflare Pages
- 数据安全依赖 Supabase RLS 策略，不是密钥隐藏
- 定期轮换 Cloudflare API Token

## 相关文档

- [Cloudflare Pages 部署指南](docs/CLOUDFLARE_PAGES_DEPLOYMENT.md)
- [环境变量配置](.env.example)
- [Cloudflare API 文档](https://developers.cloudflare.com/api/operations/pages-project-update-project)

## 时间线

- **2026-08-06 09:30** - 发现手机报错"应用初始化失败"
- **2026-08-06 09:42** - 诊断确认环境变量未配置
- **2026-08-06 09:50** - 通过 API 添加环境变量
- **2026-08-06 09:53** - 触发重新部署
- **2026-08-06 09:58** - 部署成功，修复完成

---

**修复人员**: Claude Opus 4.7  
**Cloudflare API Token**: 存储于 `.env.cloudflare`  
**生产 URL**: https://exhibition-buyer-app.pages.dev
