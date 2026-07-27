# 修复 Booths 表 RLS 权限错误

## 问题
创建摊位时报错：`PostgresException(message: new row violates row-level security policy for table "booths", code: 42501)`

## 原因
与 events 表相同的问题：RLS 策略中的子查询无法访问 users 表的 team_id

## 解决方案
使用已创建的 `public.current_user_team_id()` SECURITY DEFINER 函数

## 执行步骤

1. 打开 Supabase Dashboard: https://supabase.com/dashboard
2. 选择项目: ppwjblvnixqeympfcqgs
3. 进入 SQL Editor
4. 复制并执行以下 SQL：

```sql
-- 删除旧的 booths 策略
DROP POLICY IF EXISTS "Team members can insert booths" ON booths;
DROP POLICY IF EXISTS "Team members can update booths" ON booths;
DROP POLICY IF EXISTS "Team members can delete booths" ON booths;
DROP POLICY IF EXISTS "Team members can view booths" ON booths;

-- 重新创建策略，使用 SECURITY DEFINER 函数
CREATE POLICY "Team members can view booths"
  ON booths FOR SELECT
  USING (
    event_id IN (
      SELECT id FROM events WHERE team_id = public.current_user_team_id()
    )
  );

CREATE POLICY "Team members can insert booths"
  ON booths FOR INSERT
  WITH CHECK (
    event_id IN (
      SELECT id FROM events WHERE team_id = public.current_user_team_id()
    )
    AND public.current_user_team_id() IS NOT NULL
  );

CREATE POLICY "Team members can update booths"
  ON booths FOR UPDATE
  USING (
    event_id IN (
      SELECT id FROM events WHERE team_id = public.current_user_team_id()
    )
  );

CREATE POLICY "Team members can delete booths"
  ON booths FOR DELETE
  USING (
    event_id IN (
      SELECT id FROM events WHERE team_id = public.current_user_team_id()
    )
  );
```

## 验证
执行成功后，在应用中测试创建摊位功能，应该不再报错。

## 注意
此 SQL 也已保存在: `supabase/migrations/20260727000001_fix_booths_rls_policy.sql`
