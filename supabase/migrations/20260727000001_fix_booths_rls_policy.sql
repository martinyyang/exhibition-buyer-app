-- 修复 booths 表的 RLS 策略
-- 问题：子查询 "SELECT team_id FROM users WHERE id = auth.uid()" 可能受到 users 表的 RLS 限制
-- 解决方案：使用已有的 public.current_user_team_id() 函数

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

-- 添加注释
COMMENT ON POLICY "Team members can view booths" ON booths IS
'允许团队成员查看本团队活动下的摊位';

COMMENT ON POLICY "Team members can insert booths" ON booths IS
'允许团队成员在本团队活动下创建摊位';

COMMENT ON POLICY "Team members can update booths" ON booths IS
'允许团队成员更新本团队活动下的摊位';

COMMENT ON POLICY "Team members can delete booths" ON booths IS
'允许团队成员删除本团队活动下的摊位';
