# Migration Apply Guide

## 最新待应用迁移

### 20260819000003_fix_create_team_timestamp_type.sql（2026-08-21 修订版）

**优先级**: 🔴 高 - 修复生产环境创建团队报 42804

**问题**: 创建团队时报错
`structure of query does not match function result type, code: 42804`
（`Returned type timestamp without time zone does not match expected type timestamp with time zone in column 3`）

**根因**: `create_team` 函数声明返回 `created_at TIMESTAMPTZ`，但 `teams.created_at` 实际是 `TIMESTAMP`（不带时区），类型不匹配。

**为什么之前的修复没生效**: 旧版 `000003` 用 `CREATE OR REPLACE` 修改函数返回类型——**PostgreSQL 禁止用 REPLACE 修改返回类型**，所以该迁移在生产库要么没应用、要么应用即报错，线上函数一直是 TIMESTAMPTZ 版本。

**修订内容**（2026-08-21）:
1. 改为 `DROP FUNCTION IF EXISTS create_team(TEXT, TEXT)` + `CREATE FUNCTION`（幂等，可重复执行）
2. 返回类型改为 `created_at TIMESTAMP`（匹配表结构）
3. 参数名改为 `p_name`（与客户端 `team_service.dart` 的 `p_name`/`p_password` 对齐，PostgREST 按参数名匹配）
4. `UPDATE users` 的 WHERE 使用限定列名 `users.id`（未限定名 `id` 会与 RETURNS TABLE 输出参数冲突，PG 报 `column reference "id" is ambiguous`，已在真实 PostgreSQL 14 验证）

**已用真实 PostgreSQL 14 验证**（2026-08-21，临时容器）:
- 复现: harden 版（TIMESTAMPTZ）调用报 42804（与生产错误一致）
- 应用迁移: DROP/CREATE/GRANT/COMMENT 全部成功
- 签名: `created_at timestamp without time zone` ✅
- 调用: `SELECT * FROM create_team('t2','p2')` 成功返回 4 列 ✅
- 幂等: 迁移重复执行成功 ✅

**应用方法**:

#### 方法 1: Supabase CLI（推荐）
```bash
supabase db push
```

#### 方法 2: SQL Editor（Supabase Dashboard）
1. 登录 Supabase Dashboard
2. 进入 SQL Editor
3. 复制 `supabase/migrations/20260819000003_fix_create_team_timestamp_type.sql` 内容
4. 执行 SQL

**验证**:
1. 在应用中测试创建团队功能
2. 确认创建成功后返回团队信息（ID、名称、创建时间、创建者ID）
3. 检查 `users.team_id` 和 `is_team_creator` 是否正确更新

---

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
