# Cloudflare Workers 代理设置指南

本指南帮助您配置 Cloudflare Workers 反向代理，以优化中国网络环境下对 Supabase 的访问速度。

## 为什么需要代理？

- **地域限制**：Supabase 服务在中国可能无法直接访问或速度很慢
- **全球团队**：代理方案允许中国团队和海外团队使用各自最优的网络路径
- **零成本**：Cloudflare Workers 免费额度（每天 10 万次请求）足够使用
- **无缝切换**：通过环境变量控制，无需修改代码

## 前置要求

- Cloudflare 账号（免费注册：https://dash.cloudflare.com/sign-up）
- 本项目的 Supabase URL（在 `.env` 文件中）

## 步骤 1：创建 Cloudflare Worker

### 1.1 登录 Cloudflare Dashboard

访问 https://dash.cloudflare.com/ 并登录您的账号。

### 1.2 创建 Worker

1. 点击左侧菜单的 **"Workers & Pages"**
2. 点击 **"Create application"** 按钮
3. 选择 **"Create Worker"**
4. 为 Worker 命名（例如：`supabase-proxy`）
5. 点击 **"Deploy"** 创建默认 Worker

### 1.3 编辑 Worker 代码

1. 点击 **"Edit code"** 按钮
2. 删除默认代码，粘贴以下代码：

```javascript
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const targetUrl = 'https://ppwjblvnixqeympfcqgs.supabase.co';
    
    // 构建目标 URL
    const supabaseUrl = new URL(targetUrl);
    supabaseUrl.pathname = url.pathname;
    supabaseUrl.search = url.search;
    
    // 创建新请求，保留所有原始请求信息
    const modifiedRequest = new Request(supabaseUrl.toString(), {
      method: request.method,
      headers: request.headers,
      body: request.body,
      redirect: 'follow'
    });
    
    // 转发请求并返回响应
    const response = await fetch(modifiedRequest);
    
    // 创建新的响应对象，添加 CORS 头
    const modifiedResponse = new Response(response.body, response);
    modifiedResponse.headers.set('Access-Control-Allow-Origin', '*');
    modifiedResponse.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
    modifiedResponse.headers.set('Access-Control-Allow-Headers', '*');
    
    // 处理 OPTIONS 预检请求
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
          'Access-Control-Allow-Headers': '*',
          'Access-Control-Max-Age': '86400',
        }
      });
    }
    
    return modifiedResponse;
  }
};
```

3. 点击 **"Save and Deploy"**

### 1.4 记录 Worker URL

部署成功后，您会看到 Worker URL，格式类似：

```
https://supabase-proxy.your-subdomain.workers.dev
```

**请保存这个 URL**，稍后需要配置到应用中。

## 步骤 2：测试 Worker

在浏览器或命令行测试 Worker 是否正常工作：

```bash
# 测试 API 访问
curl https://supabase-proxy.your-subdomain.workers.dev/rest/v1/

# 应该返回类似以下内容：
# {"code":"PGRST001","message":"Schema cache not loaded","details":"..."}
# 或者正常的 API 响应
```

如果返回错误或无响应，请检查：
1. Worker 代码是否正确部署
2. Supabase URL 是否填写正确
3. Worker 是否处于激活状态

## 步骤 3：配置应用使用代理

### 3.1 更新 .env 文件

编辑项目根目录的 `.env` 文件，添加 Worker URL：

```env
# Supabase项目URL（直连，海外使用）
SUPABASE_URL=https://ppwjblvnixqeympfcqgs.supabase.co

# Cloudflare Workers 代理URL（中国使用）
SUPABASE_PROXY_URL=https://supabase-proxy.your-subdomain.workers.dev

# Supabase匿名公钥
SUPABASE_ANON_KEY=your-anon-key-here
```

### 3.2 工作原理

- 当 `SUPABASE_PROXY_URL` 配置且不为空时，应用会使用代理访问
- 当 `SUPABASE_PROXY_URL` 为空或注释掉时，应用会直连 `SUPABASE_URL`
- 启动时会在控制台输出使用的连接方式：
  - `✓ Using Supabase proxy URL (China-optimized)` - 使用代理
  - `✓ Using direct Supabase URL` - 直连

## 步骤 4：验证配置

### 4.1 启动应用

```bash
flutter run -d chrome
```

### 4.2 检查启动日志

在控制台中查看以下输出：

```
✓ Loaded .env file successfully
✓ Using Supabase proxy URL (China-optimized)
Environment variables:
  SUPABASE_URL: ✓ found
  SUPABASE_PROXY_URL: ✓ found (active)
  SUPABASE_ANON_KEY: ✓ found
```

如果看到 `✓ found (active)` 说明代理已启用。

### 4.3 测试功能

测试以下核心功能：
- [ ] 登录/注册
- [ ] 加载展会列表
- [ ] 上传照片
- [ ] 添加旗子标注

## 多环境配置

### 场景 A：中国团队使用代理

```env
SUPABASE_PROXY_URL=https://supabase-proxy.your-subdomain.workers.dev
```

### 场景 B：海外团队直连

```env
# 注释掉或留空
# SUPABASE_PROXY_URL=
```

或者直接删除该行。

### 场景 C：混合团队

每个团队成员根据自己的网络环境单独配置 `.env` 文件（`.env` 已在 `.gitignore` 中，不会提交到 Git）。

## 性能监控

### Cloudflare Workers 免费额度

- **请求次数**：每天 10 万次（足够中小团队使用）
- **CPU 时间**：每次请求 10ms
- **响应延迟**：通常 < 100ms

查看使用情况：
1. 登录 Cloudflare Dashboard
2. 进入 **Workers & Pages** → 选择您的 Worker
3. 点击 **"Metrics"** 查看请求统计

### 性能对比测试

测试代理前后的性能差异：

```bash
# 测试直连速度（从中国网络）
time curl https://ppwjblvnixqeympfcqgs.supabase.co/rest/v1/

# 测试代理速度
time curl https://supabase-proxy.your-subdomain.workers.dev/rest/v1/
```

预期：代理速度应显著快于直连（中国网络环境）。

## 常见问题

### Q1: Worker 返回 403 或 CORS 错误

**原因**：CORS 头配置不正确。

**解决**：检查 Worker 代码中的 CORS 头设置，确保包含：
```javascript
modifiedResponse.headers.set('Access-Control-Allow-Origin', '*');
```

### Q2: 应用启动时显示 "○ not configured"

**原因**：`SUPABASE_PROXY_URL` 未配置或为空。

**解决**：
1. 检查 `.env` 文件是否存在 `SUPABASE_PROXY_URL` 配置
2. 确认该配置有值且格式正确（以 `https://` 开头）

### Q3: 代理无效，仍然很慢

**可能原因**：
1. Cloudflare Workers 在当前地区没有边缘节点
2. 网络运营商屏蔽了 Cloudflare 域名
3. Worker 代码有误，未正确转发请求

**解决**：
1. 测试 Worker URL 是否可直接访问
2. 查看浏览器开发者工具的网络请求，检查是否使用了代理 URL
3. 尝试备选方案：使用自有服务器部署 Nginx 代理

### Q4: 超出免费额度怎么办？

Cloudflare Workers 免费额度为每天 10 万次请求。如果超出：

**选项 1**：升级到 Workers Paid 计划（$5/月，包含 1000 万次请求）

**选项 2**：部署到自己的服务器（参考方案见计划文档中的"阿里云服务器 Nginx 代理"部分）

## 备选方案：使用自有服务器

如果您有阿里云或其他云服务器（如截图中的美国服务器），可以部署 Nginx 代理：

```bash
# SSH 连接服务器
ssh root@your-server-ip

# 创建 Nginx 配置
cat > /etc/nginx/conf.d/supabase-proxy.conf <<'EOF'
server {
    listen 80;
    server_name your-server-ip;

    location / {
        proxy_pass https://ppwjblvnixqeympfcqgs.supabase.co;
        proxy_set_header Host ppwjblvnixqeympfcqgs.supabase.co;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_ssl_server_name on;
        
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, PATCH, OPTIONS';
        add_header Access-Control-Allow-Headers '*';
    }
}
EOF

# 重启 Nginx
nginx -t && nginx -s reload
```

然后在 `.env` 中配置：
```env
SUPABASE_PROXY_URL=http://your-server-ip
```

**注意**：自有服务器方案需要您自行维护和监控服务。

## 安全建议

1. **不要泄露 Worker URL**：虽然有 Supabase API Key 保护，但仍建议限制 Worker 访问（Cloudflare 付费功能）
2. **监控异常流量**：定期检查 Cloudflare Metrics，防止被滥用
3. **保护 .env 文件**：`.env` 已在 `.gitignore` 中，确保不会提交敏感信息到 Git

## 下一步优化

当前方案验证通过后，可以考虑：

1. **图片 CDN 加速**：将 Supabase Storage 的图片迁移到阿里云 OSS
2. **智能地域检测**：自动检测用户地域并选择最优网络路径
3. **离线上传队列**：增强展会现场弱网环境下的用户体验

详细方案请参考：`C:\Users\Administrator\.claude\plans\jolly-roaming-dove.md`

## 支持

如有问题，请：
1. 查看 Cloudflare Workers 文档：https://developers.cloudflare.com/workers/
2. 提交 GitHub Issue
3. 联系团队技术负责人
