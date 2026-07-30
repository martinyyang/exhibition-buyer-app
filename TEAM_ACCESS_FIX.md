# 诊断报告：Remote用户无法配置团队问题

## 问题汇总

### 1. 用户列表
当前系统有5个测试用户：
- test@123.com (buyer) - 已加入 northpark 团队
- test1@123.com (buyer) - 无团队
- test2@123.com (buyer) - 无团队
- test4@123.com (buyer) - 已加入 northpark 团队
- **remote@123.com (remote) - 无团队** ⚠️ 问题所在

### 2. 测试密码
常用测试密码（根据代码惯例推测）：
- test123456
- Test123456!
- 123456

### 3. Remote用户无法配置团队的根本原因

**问题诊断：**
Teams表的RLS策略过于严格，只允许用户查看"已加入的团队"：

```sql
CREATE POLICY "Team members can view team"
  ON teams FOR SELECT
  USING (
    id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );
```

**问题场景：**
1. Remote用户的 `team_id` 为 NULL（未加入任何团队）
2. 当用户尝试在设置页面加入团队时，前端调用 `joinTeamByInviteCodeOrName()`
3. 该函数需要查询所有teams来匹配邀请码或名称
4. 但由于RLS策略限制，`team_id` 为 NULL 的用户无法查询任何团队
5. 查询返回空结果，导致无法加入任何团队（包括创建新团队）

**死锁逻辑：**
- 要查看团队 → 必须已经是团队成员
- 要成为团队成员 → 必须先查看并加入团队
- 结果：无法加入任何团队！

## 解决方案

### 已创建的修复Migration

文件：`supabase/migrations/20260730000000_fix_teams_rls_for_joining.sql`

```sql
-- 删除旧的限制性策略
DROP POLICY IF EXISTS "Team members can view team" ON teams;

-- 添加新策略：所有认证用户都可以查看所有团队（用于浏览和加入）
CREATE POLICY "Authenticated users can view all teams"
  ON teams FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- 添加策略：所有认证用户都可以创建团队
CREATE POLICY "Authenticated users can create teams"
  ON teams FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- 添加策略：团队成员可以更新自己的团队信息
CREATE POLICY "Team members can update own team"
  ON teams FOR UPDATE
  USING (
    id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );
```

### 应用修复的方法

#### 方法1：通过Supabase Dashboard（推荐）
1. 访问 https://app.supabase.com/
2. 选择项目：exhibition-buyer-app
3. 进入 SQL Editor
4. 复制并执行上述SQL

#### 方法2：通过命令行（如果已安装Supabase CLI）
```bash
cd supabase
supabase db push
```

#### 方法3：通过psql（如果有直接数据库访问权限）
```bash
psql "postgresql://postgres:[password]@db.ppwjblvnixqeympfcqgs.supabase.co:5432/postgres" \
  -f migrations/20260730000000_fix_teams_rls_for_joining.sql
```

## 修复后的效果

✅ Remote用户可以：
1. 查看所有团队列表
2. 通过邀请码加入现有团队
3. 通过团队名加入现有团队
4. 创建新团队

✅ 保持安全性：
- 只有认证用户可以查看团队
- 只有团队成员可以修改团队信息
- 所有用户可以创建新团队

## 后续测试步骤

1. 应用上述SQL修复
2. 使用 remote@123.com 登录
3. 进入设置页面
4. 尝试输入邀请码或团队名 "northpark"
5. 验证是否成功加入团队

## 相关文件

- 设置页面：`lib/features/settings/screens/settings_screen.dart`
- 团队服务：`lib/features/team/services/team_service.dart`
- 初始Schema：`supabase/migrations/20260722000000_initial_schema.sql`
- 修复Migration：`supabase/migrations/20260730000000_fix_teams_rls_for_joining.sql`
