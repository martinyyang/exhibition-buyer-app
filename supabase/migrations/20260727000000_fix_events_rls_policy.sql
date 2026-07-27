-- 修复 events 表的 RLS 策略
-- 问题：子查询 "SELECT team_id FROM users WHERE id = auth.uid()" 可能受到 users 表的 RLS 限制
-- 解决方案：使用 SECURITY DEFINER 函数绕过 RLS，或者简化策略

-- 方案1：创建一个 SECURITY DEFINER 函数来获取用户的 team_id
CREATE OR REPLACE FUNCTION auth.user_team_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT team_id FROM public.users WHERE id = auth.uid();
$$;

-- 删除旧的 events 策略
DROP POLICY IF EXISTS "Team members can insert events" ON events;
DROP POLICY IF EXISTS "Team members can update events" ON events;
DROP POLICY IF EXISTS "Team members can delete events" ON events;
DROP POLICY IF EXISTS "Team members can view events" ON events;

-- 重新创建策略，使用 SECURITY DEFINER 函数
CREATE POLICY "Team members can view events"
  ON events FOR SELECT
  USING (team_id = auth.user_team_id());

CREATE POLICY "Team members can insert events"
  ON events FOR INSERT
  WITH CHECK (
    team_id = auth.user_team_id()
    AND auth.user_team_id() IS NOT NULL
  );

CREATE POLICY "Team members can update events"
  ON events FOR UPDATE
  USING (team_id = auth.user_team_id());

CREATE POLICY "Team members can delete events"
  ON events FOR DELETE
  USING (team_id = auth.user_team_id());

-- 添加注释
COMMENT ON FUNCTION auth.user_team_id() IS
'安全函数：绕过 RLS 获取当前用户的 team_id。用于 events 表的 RLS 策略。';
