# Supabase数据库配置检查清单

请按顺序完成以下配置步骤：

## ☐ 1. 创建Supabase项目

- [ ] 访问 https://supabase.com/ 并登录/注册
- [ ] 创建新项目 `exhibition-buyer-app`
- [ ] 选择区域（推荐：Singapore 或 Tokyo）
- [ ] 设置数据库密码并保存
- [ ] 等待项目初始化完成（约2分钟）

## ☐ 2. 获取API密钥

- [ ] 进入 Settings > API
- [ ] 复制 Project URL
- [ ] 复制 anon public key
- [ ] 复制 service_role key（保密，不要提交到代码仓库）

## ☐ 3. 配置环境变量

- [ ] 复制 `.env.example` 为 `.env`
- [ ] 在 `.env` 中填入实际的 SUPABASE_URL
- [ ] 在 `.env` 中填入实际的 SUPABASE_ANON_KEY
- [ ] 验证 `.gitignore` 已包含 `.env`（防止泄露密钥）

## ☐ 4. 执行数据库迁移

- [ ] 打开 Supabase Dashboard > SQL Editor
- [ ] 点击 "New query"
- [ ] 复制 `supabase/migrations/20260722000000_initial_schema.sql` 全部内容
- [ ] 粘贴到SQL编辑器
- [ ] 点击 "Run" 执行
- [ ] 等待执行完成（约10-20秒）
- [ ] 检查是否有错误信息

## ☐ 5. 验证表创建成功

进入 Table Editor，确认以下表已创建：

- [ ] teams
- [ ] users
- [ ] events
- [ ] booths
- [ ] photos
- [ ] flags
- [ ] exchange_settings
- [ ] formula_history
- [ ] comments

## ☐ 6. 创建Storage存储桶

- [ ] 进入 Storage
- [ ] 创建新存储桶 `photos`
- [ ] 勾选 "Public bucket"
- [ ] 点击 "Create bucket"

## ☐ 7. 配置Storage策略

在 `photos` 存储桶的 Policies 标签中，执行以下SQL：

```sql
-- 允许认证用户上传
CREATE POLICY "Authenticated users can upload photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'photos');

-- 允许公开访问
CREATE POLICY "Public photos are viewable by anyone"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'photos');

-- 允许用户删除自己的照片
CREATE POLICY "Users can delete own photos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'photos');
```

- [ ] 执行上传策略
- [ ] 执行查看策略
- [ ] 执行删除策略

## ☐ 8. 启用Realtime

- [ ] 进入 Settings > API
- [ ] 滚动到 "Realtime" 部分
- [ ] 确认 Realtime 已启用（默认开启）
- [ ] 记录 Realtime URL（通常与 Project URL 相同）

## ☐ 9. 更新Flutter应用配置

编辑 `lib/core/services/supabase_client.dart`：

- [ ] 替换 `YOUR_SUPABASE_URL` 为实际URL
- [ ] 替换 `YOUR_ANON_KEY` 为实际anon key
- [ ] 保存文件

## ☐ 10. 测试数据库连接

- [ ] 运行应用：`flutter run`
- [ ] 尝试注册新用户
- [ ] 在 Supabase Dashboard > Authentication > Users 中查看是否成功创建用户
- [ ] 在 Table Editor > users 表中查看用户记录

## ☐ 11. 创建测试数据（可选）

手动在 Table Editor 中创建测试数据：

- [ ] 创建一个测试小组（teams表）
- [ ] 将测试用户关联到小组（users表）
- [ ] 创建测试场次（events表）
- [ ] 创建测试摊位（booths表）

## ☐ 12. 验证RLS策略

- [ ] 使用测试用户登录应用
- [ ] 尝试访问其他小组的数据（应该失败）
- [ ] 尝试访问本小组的数据（应该成功）
- [ ] 验证数据隔离是否正常工作

## 常见问题排查

### 问题：执行迁移时报错 "extension uuid-ossp does not exist"
**解决**：在SQL Editor中先执行：
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### 问题：RLS策略导致查询返回空数组
**解决**：
1. 检查用户是否已关联到team
2. 检查RLS策略中的条件是否正确
3. 临时禁用RLS测试（开发阶段）：在Table Editor > 表设置中关闭RLS

### 问题：Storage上传失败
**解决**：
1. 检查存储桶策略是否正确配置
2. 检查文件大小是否超过限制（免费版50MB）
3. 查看 Logs > Storage 中的错误信息

### 问题：Realtime订阅没有触发
**解决**：
1. 确认Realtime已启用（Settings > API）
2. 检查表是否启用了Realtime（Table Editor > 表设置）
3. 查看 Logs > Realtime 中的连接状态

## 配置完成标志

当以下条件都满足时，数据库配置完成：

✅ 所有表已创建且结构正确
✅ RLS策略已启用且工作正常
✅ Storage存储桶已创建并可以上传文件
✅ Realtime订阅可以正常工作
✅ 应用可以成功连接并执行CRUD操作
✅ 数据隔离正常（小组间数据不互通）

## 下一步

配置完成后，继续任务 #21：实现用户认证和颜色标识分配
