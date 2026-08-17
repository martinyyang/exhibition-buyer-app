# 团队数据安全加固迁移应用指南

> 迁移文件：`supabase/migrations/20260817000001_harden_team_security.sql`

## 背景：修复的漏洞

### 漏洞1（CRITICAL）：团队密码明文泄露

任何已注册用户都可以直接查询所有团队的密码：

```sql
-- 旧行为：以下查询返回所有团队的所有列（含 password）
SELECT * FROM teams;
```

**根因**：RLS 行策略只控制"能看到哪些行"，不控制"能看到哪些列"。
旧策略 `Authenticated users can view teams basic info (USING auth.uid() IS NOT NULL)`
允许所有认证用户读取 teams 表的全部列，包括明文存储的 `password`。

### 漏洞2（CRITICAL）：绕过密码验证加入任意团队

任意用户可以直接修改自己的 `team_id` 加入任何团队，无需密码：

```sql
-- 旧行为：直接把自己加入目标团队（配合漏洞1 可枚举团队 ID）
UPDATE users SET team_id = '<任意团队ID>' WHERE id = auth.uid();
```

**根因**：`users` 表 UPDATE 策略允许用户修改自己记录的所有字段（含 `team_id`），
而 `teams` 表 SELECT 策略允许枚举所有团队。

## 修复内容

| 变更 | 说明 |
|------|------|
| 列级权限收缩 | `authenticated` 角色不再拥有 `teams.password` 列的任何权限 |
| teams SELECT 行策略 | 仅能查看自己所在团队（阻断团队枚举） |
| users UPDATE 列级收缩 | 撤销客户端对 `team_id` 列的直接修改 |
| `join_team` RPC（新） | 服务端验证密码后原子设置 `team_id`，防绕过 |
| `create_team` RPC（新） | 创建团队 + 设置创建者 + 加入团队，原子完成 |
| 缺失 schema 补齐 | `teams.creator_id`、`users.last_seen`、`current_user_team_id()` 纳入版本控制 |
| 防枚举 | `verify_team_password` 统一失败消息 |

## 应用步骤

1. 打开 Supabase 控制台 → SQL Editor
2. 复制 `supabase/migrations/20260817000001_harden_team_security.sql` 全部内容执行
3. 确认输出无错误

> **幂等重试**：全部语句均为幂等（`IF NOT EXISTS` / `CREATE OR REPLACE` / `DROP POLICY IF EXISTS`）。
> 若之前执行失败（如 `42703: column "is_team_creator" does not exist`），无需回滚，
> 直接重新执行本文件即可。`is_team_creator` 列会自动补齐，并按"每团队第一个 remote 成员"
> 规则回填创建者标记。

## 验证修复生效

```sql
-- 1. 验证密码列不可读（应报权限错误）
SELECT password FROM teams LIMIT 1;
-- 期望结果：ERROR: permission denied for column password

-- 2. 验证团队列表不可枚举（应返回空/仅自己的团队）
SELECT * FROM teams;
-- 期望结果：仅返回当前用户所在团队（未加入任何团队时返回空）

-- 3. 验证 join_team RPC 可用
SELECT * FROM join_team('团队名', '密码');
-- 期望结果：返回团队信息，且当前用户 team_id 已更新
```

## 配套代码变更

本迁移需要与以下代码变更**一起部署**（应用版本 v1.0.6+）：

- `TeamService.createTeam` / `joinTeamByIdentifierAndPassword` 改调 RPC
- `Team` 模型移除 `password` 字段
- 设置页加入团队对话框新增密码输入框（修复此前必败的流程）
- 删除越权的 `addMember` / `removeMember` / `updateUserTeam` / `getAllTeams`

> **注意**：应用新代码前必须先执行本迁移，否则加入/创建团队功能不可用
> （客户端已不再直接写 `teams` / `users.team_id`）。
