# 生产环境迁移应用指南

## 当前待应用迁移

### 20260819000003_fix_create_team_timestamp_type.sql

**问题**：创建团队时报错 `PostgreSQL exception: structure of query does not match function result type, code: 42804, details: Returned type timestamp without time zone does not match expected type timestamp with time zone in column 3`

**根因**：`create_team` 函数的 `RETURNS TABLE` 声明 `created_at TIMESTAMPTZ`（带时区），但 `teams` 表的 `created_at` 列实际是 `TIMESTAMP`（不带时区），导致返回类型不匹配。

**修复**：将 `create_team` 函数的返回类型改为 `TIMESTAMP`（不带时区），匹配实际表结构。

**应用方式**：

```bash
# 在 Supabase Dashboard > SQL Editor 中执行
# 或使用 Supabase CLI
supabase db push
```

**验证**：
1. 登录生产环境
2. 尝试创建新团队
3. 确认能够成功创建并返回团队信息

**影响范围**：`create_team` RPC 函数的返回类型

**回滚**：如需回滚，执行：
```sql
-- 回滚到 TIMESTAMPTZ（会导致错误重现）
CREATE OR REPLACE FUNCTION public.create_team(p_team_name TEXT, p_password TEXT)
RETURNS TABLE (id UUID, name TEXT, created_at TIMESTAMPTZ, creator_id UUID)
...
```

### 20260819000001_fix_users_select_permissions.sql

**问题**：登录后无法读取用户的 `team_id`，导致路由逻辑无法正确判断是否有团队。

**根因**：`20260817000001_harden_team_security.sql` 安全加固时限制了 `users.team_id` 的 UPDATE 权限（防止绕过密码验证加入团队），但未明确授予 SELECT 权限，导致生产环境的 `currentUserDataProvider` 查询失败。

**修复**：明确授予 `authenticated` 角色对 `users` 表所有列的 SELECT 权限，同时保持 UPDATE 仅限于安全列。

**应用方式**：

```bash
# 在 Supabase Dashboard > SQL Editor 中执行
# 或使用 Supabase CLI
supabase db push
```

**验证**：
1. 登录生产环境
2. 检查能否正确读取用户的 `team_id`
3. 确认已加入团队的用户能够直接进入 `/events` 页面

**影响范围**：所有认证用户的数据读取权限

**回滚**：如需回滚，执行：
```sql
-- 回滚到仅允许查看自己的数据
REVOKE SELECT ON users FROM authenticated;
CREATE POLICY "Users can view own data"
  ON users FOR SELECT
  USING (auth.uid() = id);
```

## 历史迁移记录

### 20260817000002_fix_rpc_ambiguity_and_cleanup_policies.sql ✅
- 修复 `create_team` / `join_team` RPC 的列名歧义问题
- 清理历史残留的 RLS 策略

### 20260817000001_harden_team_security.sql ✅
- 修复团队密码泄露漏洞
- 限制 `users.team_id` 的直接修改
- 新增 `join_team` / `create_team` RPC

### 20260812000001_secure_team_password.sql ✅
- 创建 `verify_team_password` 和 `get_team_with_password` 函数
- 服务端验证团队密码
