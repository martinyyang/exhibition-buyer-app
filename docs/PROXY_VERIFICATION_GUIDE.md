# 代理方案验证指南

## 快速验证清单

### ✅ 步骤 1：配置 Cloudflare Worker

参考 `CLOUDFLARE_PROXY_SETUP.md` 完成 Worker 创建，获得 URL：
```
https://your-worker-name.your-subdomain.workers.dev
```

### ✅ 步骤 2：测试 Worker 可用性

**方法 A：浏览器测试**
```
在浏览器访问：
https://your-worker-name.your-subdomain.workers.dev/rest/v1/

预期结果：显示 JSON 响应（可能是错误信息，但说明代理工作正常）
```

**方法 B：命令行测试**
```bash
# 在项目目录执行
curl https://your-worker-name.your-subdomain.workers.dev/rest/v1/

# 预期输出：
# {"code":"PGRST001",...} 或其他 JSON 响应
```

如果返回 HTML 错误页面或无响应，说明 Worker 配置有问题。

---

### ✅ 步骤 3：更新本地配置

编辑 `.env` 文件：
```env
# 添加这一行（替换为您的实际 Worker URL）
SUPABASE_PROXY_URL=https://your-worker-name.your-subdomain.workers.dev
```

---

### ✅ 步骤 4：本地运行应用

```bash
# Web 端测试
flutter run -d chrome
```

**查看启动日志**，确认代理已启用：

```
✓ Loaded .env file successfully
✓ Using Supabase proxy URL (China-optimized)   <-- 这行说明代理已启用
Environment variables:
  SUPABASE_URL: ✓ found
  SUPABASE_PROXY_URL: ✓ found (active)         <-- 这行说明代理配置生效
  SUPABASE_ANON_KEY: ✓ found
Initializing Supabase...
✓ Supabase initialized successfully
```

如果看到：
- `✓ Using direct Supabase URL` - 说明代理未生效，检查配置
- `○ not configured` - 说明 `SUPABASE_PROXY_URL` 为空或未配置

---

### ✅ 步骤 5：功能测试

在浏览器中测试核心功能：

| 功能 | 测试步骤 | 预期结果 |
|------|---------|---------|
| **登录** | 输入账号密码登录 | 成功进入应用 |
| **加载展会** | 查看展会列表 | 正常显示展会数据 |
| **加载摊位** | 点击展会查看摊位 | 正常显示摊位列表 |
| **上传照片** | 点击上传按钮选择图片 | 照片上传成功 |
| **添加旗子** | 在照片上点击添加标注 | 旗子正常显示 |

**检查网络请求**（开发者工具）：
1. 按 F12 打开开发者工具
2. 切换到 Network 标签
3. 刷新页面，查看请求
4. 确认请求地址是 Worker URL 而不是直连 Supabase

例如：
```
✓ https://your-worker-name.your-subdomain.workers.dev/rest/v1/events
✗ https://ppwjblvnixqeympfcqgs.supabase.co/rest/v1/events
```

---

### ✅ 步骤 6：性能对比测试（可选）

**测试 A：不使用代理**
```env
# 注释掉代理配置
# SUPABASE_PROXY_URL=
```

重启应用，记录响应时间：
- 登录耗时：___ 秒
- 加载展会列表：___ 秒
- 上传 1MB 图片：___ 秒

**测试 B：使用代理**
```env
# 启用代理
SUPABASE_PROXY_URL=https://your-worker-name.your-subdomain.workers.dev
```

重启应用，记录响应时间：
- 登录耗时：___ 秒
- 加载展会列表：___ 秒
- 上传 1MB 图片：___ 秒

**预期**：中国网络环境下，代理速度应明显快于直连。

---

## 高级验证：中国网络环境测试

### 方法 1：使用 VPN 模拟中国网络

如果您不在中国：
1. 连接到中国的 VPN 服务器
2. 重复上述步骤 4-5 的功能测试
3. 对比使用代理 vs 不使用代理的速度

### 方法 2：让中国团队成员测试

1. 将代码推送到 GitHub
2. 中国团队成员拉取代码
3. 配置 `.env` 文件（填入 Worker URL）
4. 本地运行测试

### 方法 3：部署到测试环境

```bash
# 构建 Web 版本
flutter build web

# 部署到服务器或 GitHub Pages
# 让中国团队访问测试
```

---

## 验证通过标准

### ✅ 基础验证通过
- [ ] Worker 可以访问（浏览器或 curl 测试）
- [ ] 应用启动日志显示 "Using Supabase proxy URL"
- [ ] 所有核心功能正常（登录、加载、上传、标注）
- [ ] 浏览器开发者工具显示请求走 Worker URL

### ✅ 性能验证通过（中国网络）
- [ ] 代理速度 > 直连速度（或至少不更慢）
- [ ] API 请求延迟 < 3 秒
- [ ] 图片上传成功率 > 90%

### ✅ 多地域协作验证（可选）
- [ ] 中国团队使用代理正常工作
- [ ] 海外团队直连正常工作
- [ ] 数据同步无延迟或冲突

---

## 常见验证问题

### Q1: 启动日志显示 "not configured"

**原因**：`SUPABASE_PROXY_URL` 未配置或为空

**解决**：
```bash
# 检查 .env 文件
cat .env | grep PROXY

# 应该看到：
SUPABASE_PROXY_URL=https://your-worker-name...

# 如果是空的：
SUPABASE_PROXY_URL=

# 需要填入实际的 Worker URL
```

### Q2: 应用启动报错 "Failed to initialize"

**可能原因**：
1. Worker URL 格式错误（必须以 `https://` 开头）
2. Worker 未正确部署
3. Worker 代码有误

**解决**：
```bash
# 1. 测试 Worker 是否可访问
curl https://your-worker-name.your-subdomain.workers.dev/rest/v1/

# 2. 检查 .env 文件格式
# 确保没有多余的空格或引号
SUPABASE_PROXY_URL=https://your-worker-name.your-subdomain.workers.dev
```

### Q3: 功能正常但网络请求仍然是直连 URL

**原因**：代理配置未生效，应用仍使用直连

**解决**：
1. 确认启动日志显示 "Using Supabase proxy URL"
2. 完全关闭应用并重新启动（热重载可能不生效）
3. 清除 Flutter 缓存：`flutter clean && flutter pub get`

### Q4: 使用代理后反而更慢

**可能原因**：
1. Cloudflare 在您的地区没有良好的边缘节点
2. Worker 添加了额外的延迟
3. 直连本身在您的网络环境下就很快

**解决**：
- 如果您在海外：**不需要使用代理**，直连即可
- 如果您在中国且代理仍慢：考虑备选方案（自有服务器 Nginx 代理）

---

## 验证成功后的下一步

### 1. 推送代码到 GitHub

```bash
git push origin master
```

### 2. 团队配置指南

创建团队内部文档，告知成员：
- **中国团队**：配置 `SUPABASE_PROXY_URL`
- **海外团队**：`SUPABASE_PROXY_URL` 留空

### 3. 生产环境部署

如果本地验证通过，可以部署到生产环境：

```bash
# 构建 Web 生产版本
flutter build web --release

# 确保 .env 配置正确（代理 URL）
# 部署到托管服务
```

### 4. 监控和优化

- 定期检查 Cloudflare Workers Metrics（请求量、延迟）
- 收集用户反馈（特别是中国用户的使用体验）
- 如有必要，升级到阿里云 OSS 图片加速方案

---

## 如果验证失败

### 方案 A：使用您的阿里云服务器

参考 `CLOUDFLARE_PROXY_SETUP.md` 中的"备选方案：使用自有服务器"部分，
在您的服务器（47.253.70.154）上部署 Nginx 代理。

### 方案 B：升级到完整方案

如果 Cloudflare 效果不理想，可以实施：
- API 代理（Cloudflare 或自有服务器）
- 图片加速（阿里云 OSS）
- 离线队列（本地优先）

详细方案见：`C:\Users\Administrator\.claude\plans\jolly-roaming-dove.md`

---

## 总结

验证的核心是**确认应用使用了代理并且功能正常**。关键检查点：

1. ✅ Worker 可访问
2. ✅ 启动日志显示代理已启用
3. ✅ 功能测试全部通过
4. ✅ 浏览器网络请求走 Worker URL

如果以上四点都满足，说明代理配置成功！
