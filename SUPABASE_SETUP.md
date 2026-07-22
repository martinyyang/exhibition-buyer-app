# Supabase配置指南

本项目使用Supabase作为后端服务，您需要完成以下配置步骤：

## 1. 注册Supabase账号

访问 https://supabase.com 注册免费账号

## 2. 创建新项目

1. 登录后点击 "New Project"
2. 填写项目信息：
   - Name: `exhibition-buyer-app` (或您喜欢的名称)
   - Database Password: 设置一个强密码并保存
   - Region: 选择距离您最近的区域
3. 点击 "Create new project"，等待项目初始化（约2分钟）

## 3. 运行数据库迁移

1. 在Supabase项目页面，点击左侧菜单的 "SQL Editor"
2. 点击 "New Query"
3. 将 `supabase/migrations/001_initial_schema.sql` 文件的全部内容复制粘贴到编辑器
4. 点击 "Run" 执行SQL脚本
5. 验证执行成功（应该显示 "Success. No rows returned"）

## 4. 配置Storage

1. 点击左侧菜单的 "Storage"
2. 点击 "Create a new bucket"
3. 设置：
   - Name: `exhibition-photos`
   - Public bucket: 勾选 ✅（允许公开访问照片）
4. 点击 "Create bucket"

## 5. 获取API密钥

1. 点击左侧菜单的 "Settings" → "API"
2. 找到以下信息：
   - Project URL: `https://xxxxx.supabase.co`
   - `anon` `public` key: 一串很长的密钥
3. 复制这两个值

## 6. 配置Flutter应用

打开 `lib/main.dart` 文件，找到以下代码：

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

替换为您的实际值：

```dart
await Supabase.initialize(
  url: 'https://xxxxx.supabase.co',  // 替换为您的Project URL
  anonKey: 'eyJhbGci...',  // 替换为您的anon key
);
```

## 7. 验证配置

运行以下命令验证配置：

```bash
# 安装依赖
flutter pub get

# 运行测试
flutter test test/unit/formula_calculator_test.dart
```

## 8. 创建测试用户（可选）

在Supabase项目页面：
1. 点击 "Authentication" → "Users"
2. 点击 "Add user" → "Create new user"
3. 填写邮箱和密码
4. 创建后，在 "Table Editor" → "users" 表中手动添加一行：
   - id: 复制刚创建的用户ID
   - email: 刚创建的邮箱
   - role: 'buyer' 或 'remote'
   - team_id: 先创建一个team记录，然后填入team_id

## 9. Row Level Security (RLS) 说明

数据库已经配置了RLS策略，确保：
- 用户只能访问自己团队的数据
- 买手可以看到同组成员的摊位和照片
- 远程团队可以看到管理的所有买手数据

## 10. 免费额度说明

Supabase免费版提供：
- ✅ 500MB 数据库存储
- ✅ 1GB 文件存储
- ✅ 2GB 带宽/月
- ✅ 50,000 月活跃用户
- ✅ 200 并发实时连接

对于5-10人团队，这些额度完全够用。

## 常见问题

### Q: SQL脚本执行失败
A: 确保您复制了完整的SQL内容，包括所有表定义和索引。可以分段执行。

### Q: Storage上传失败
A: 检查bucket名称是否为 `exhibition-photos`，且设置为public。

### Q: 实时同步不工作
A: 确认Realtime功能已启用（默认启用），检查表是否在 "Database" → "Replication" 中启用。

### Q: RLS策略导致无法访问数据
A: 临时可以在 "Authentication" → "Policies" 中禁用RLS进行测试，生产环境务必启用。

---

配置完成后，您就可以开始使用应用了！
