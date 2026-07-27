-- 修复用户更新策略，允许用户在注册后立即更新 team_id
-- 问题：现有的 UPDATE 策略可能在某些情况下阻止用户更新自己的 team_id

-- 删除旧的 UPDATE 策略
DROP POLICY IF EXISTS "Users can update own data" ON users;

-- 创建新的 UPDATE 策略，明确允许更新 team_id
CREATE POLICY "Users can update own data"
  ON users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 添加注释说明
COMMENT ON POLICY "Users can update own data" ON users IS
'允许用户更新自己的所有数据，包括 team_id。WITH CHECK 确保更新后的数据仍然属于当前用户。';
