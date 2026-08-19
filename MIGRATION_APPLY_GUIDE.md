# Migration Apply Guide

## 最新待应用迁移

### 20260819000002_fix_create_team_return_columns.sql

**优先级**: 🔴 高 - 修复生产环境创建团队功能

**问题**: 创建团队时报错 `PostgreSQL exception: could not identify column "id" in record data type, code: 42703`

**根因**: `create_team` 函数的 `RETURN QUERY SELECT (v_team).id` 无法识别 RECORD 类型中的列

**修复内容**:
1. 改用 `RETURNING teams.id INTO v_team_id` 仅获取团队 ID
2. `RETURN QUERY` 直接从 `teams` 表查询完整数据
3. 避免 RECORD 类型的字段访问问题

**应用方法**:

#### 方法 1: Supabase CLI（推荐）
```bash
supabase db push
```

#### 方法 2: SQL Editor（Supabase Dashboard）
1. 登录 Supabase Dashboard
2. 进入 SQL Editor
3. 复制 `supabase/migrations/20260819000002_fix_create_team_return_columns.sql` 内容
4. 执行 SQL

**验证**:
1. 在应用中测试创建团队功能
2. 确认创建成功后返回团队信息（ID、名称、创建时间、创建者ID）
3. 检查 `users.team_id` 是否正确更新

---

### 20260819000001_fix_users_select_permissions.sql

**优先级**: 🔴 高 - 修复生产环境登录后读取团队

**问题**: 登录后无法读取用户的 `team_id`，导致路由判断失败

**根因**: 安全加固迁移限制了 `users.team_id` 的 UPDATE 权限，但未明确授予 SELECT 权限

**修复内容**:
1. 显式授予 `authenticated` 角色对 `users` 表所有列的 SELECT 权限
2. 保持 UPDATE 权限限制（仅允许安全列）

**应用方法**:

#### 方法 1: Supabase CLI（推荐）
```bash
supabase db push
```

#### 方法 2: SQL Editor（Supabase Dashboard）
1. 登录 Supabase Dashboard
2. 进入 SQL Editor
3. 复制 `supabase/migrations/20260819000001_fix_users_select_permissions.sql` 内容
4. 执行 SQL

**验证**:
1. 退出并重新登录应用
2. 确认登录后能正确读取当前团队信息
3. 检查页面顶部是否显示 "Current Team: [团队名]"

---

## 历史迁移（已应用或待确认）

### 20260817000002_fix_rpc_ambiguity_and_cleanup_policies.sql
- 修复 RPC 函数列名歧义（42702 错误）
- 清理重复的 teams SELECT 策略

### 20260817000001_harden_team_security.sql
- 团队安全加固：限制列级权限
- 添加 `current_user_team_id()` 辅助函数

### 20260812000001_secure_team_password.sql
- 团队密码服务端验证
- 添加 `verify_team_password()` 和 `get_team_with_password()` 函数

### 20260809000002_fix_flag_number_trigger.sql
- 修复旗子编号触发器（MAX → ORDER BY + LIMIT）

### 20260803000002_make_team_password_required.sql
- 团队密码改为必填（NOT NULL）

### 20260803000001_add_team_password.sql
- 添加 `teams.password` 字段
