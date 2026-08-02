-- 修复 exchange_settings 表的 INSERT RLS 策略
-- 问题：WITH CHECK 无法在插入时正确验证 team_id
-- 解决：使用更简单的策略，只检查用户是否有 team_id

-- 删除旧的 INSERT 策略
DROP POLICY IF EXISTS "Team members can insert exchange settings" ON exchange_settings;

-- 创建新的 INSERT 策略
-- 允许任何有 team_id 的用户插入属于自己团队的记录
CREATE POLICY "Team members can insert exchange settings"
  ON exchange_settings FOR INSERT
  WITH CHECK (
    team_id = (SELECT team_id FROM users WHERE id = auth.uid())
  );

-- 同时确保 UPDATE 策略正确
DROP POLICY IF EXISTS "Team members can update exchange settings" ON exchange_settings;

CREATE POLICY "Team members can update exchange settings"
  ON exchange_settings FOR UPDATE
  USING (
    team_id = (SELECT team_id FROM users WHERE id = auth.uid())
  );
