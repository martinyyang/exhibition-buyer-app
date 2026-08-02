-- 更新 exchange_settings RLS 策略，只允许团队创建者修改公式
-- 普通成员可以查看，但不能插入或更新

-- 删除旧的 INSERT 策略
DROP POLICY IF EXISTS "Team members can insert exchange settings" ON exchange_settings;

-- 创建新的 INSERT 策略：只有团队创建者可以插入
CREATE POLICY "Team creators can insert exchange settings"
  ON exchange_settings FOR INSERT
  WITH CHECK (
    team_id = (
      SELECT team_id FROM users
      WHERE id = auth.uid()
      AND is_team_creator = TRUE
    )
  );

-- 删除旧的 UPDATE 策略
DROP POLICY IF EXISTS "Team members can update exchange settings" ON exchange_settings;

-- 创建新的 UPDATE 策略：只有团队创建者可以更新
CREATE POLICY "Team creators can update exchange settings"
  ON exchange_settings FOR UPDATE
  USING (
    team_id = (
      SELECT team_id FROM users
      WHERE id = auth.uid()
      AND is_team_creator = TRUE
    )
  );

-- SELECT 策略保持不变，所有团队成员都可以查看
-- （已在之前的迁移中创建）
