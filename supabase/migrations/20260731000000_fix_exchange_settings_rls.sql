-- 修复 exchange_settings 表的 RLS 策略
-- 问题：INSERT 操作因为 RLS 策略检查失败

-- 删除旧的 INSERT 策略
DROP POLICY IF EXISTS "Team members can insert exchange settings" ON exchange_settings;

-- 创建新的 INSERT 策略，使用更宽松的检查
CREATE POLICY "Team members can insert exchange settings"
  ON exchange_settings FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.team_id = exchange_settings.team_id
    )
  );

-- 同时确保 UPDATE 策略存在
DROP POLICY IF EXISTS "Team members can update exchange settings" ON exchange_settings;

CREATE POLICY "Team members can update exchange settings"
  ON exchange_settings FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.team_id = exchange_settings.team_id
    )
  );
