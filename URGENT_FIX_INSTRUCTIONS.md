# 🚨 紧急修复：用户无法加入团队的问题

## 问题根因

生产环境数据库中 `users` 表的 RLS (Row Level Security) UPDATE 策略存在冲突，导致用户无法更新 `team_id` 字段。

测试显示：UPDATE 请求返回成功 (200/204)，但实际上没有任何行被更新（返回空数组 `[]`）。

## 迁移冲突分析

- `20260727000001_fix_users_update_policy.sql` 创建了策略 `"Users can update own data"`
- `20260803000000_fix_users_team_id_update.sql` 试图删除 `"Users can update their own data"` (名称不匹配！)

结果：可能存在多个 UPDATE 策略或者策略名称不一致。

## 修复步骤

### 方法 1：通过 Supabase Dashboard（推荐）

1. 访问 https://supabase.com/dashboard/project/ppwjblvnixqeympfcqgs
2. 进入 **SQL Editor**
3. 执行以下 SQL：

```sql
-- 删除所有可能存在的 UPDATE 策略
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Users can update own data (not team_id)" ON users;

-- 创建唯一的 UPDATE 策略
CREATE POLICY "Users can update own data"
  ON users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
```

4. 点击 **Run** 执行

### 方法 2：使用 psql 命令行

```bash
# 需要数据库连接字符串（从 Supabase Dashboard 的 Settings > Database 获取）
psql "postgresql://postgres:[password]@db.ppwjblvnixqeympfcqgs.supabase.co:5432/postgres"

# 然后执行上面的 SQL
```

## 验证修复

修复后，运行以下测试：

```bash
node test_complete_simulation.js
```

应该看到：
```
✅ 成功加入团队!
✅ 现在可以进入应用主界面 (/events)
```

## 受影响的功能

- ❌ 用户注册后无法创建或加入团队
- ❌ 用户无法切换团队
- ❌ 团队选择页面会卡住（team_id 永远是 null）

## 临时解决方案（如果无法立即修复数据库）

使用 service_role_key 绕过 RLS：

```javascript
// 在 team_service.dart 中临时使用 service role client
final serviceRoleClient = SupabaseClient(
  supabaseUrl,
  serviceRoleKey, // 从环境变量读取
);

await serviceRoleClient
  .from('users')
  .update({'team_id': teamId})
  .eq('id', userId);
```

**注意**：这只是临时方案，不应该长期使用（service role 绕过所有安全策略）。

## 已创建的迁移文件

- ✅ `supabase/migrations/20260805000000_fix_users_update_policy_conflict.sql`
- ✅ 已修复 `20260803000000_fix_users_team_id_update.sql` 中的策略名称不匹配

下次部署时，这些迁移会自动应用到新环境。但**生产环境需要立即手动执行**。
