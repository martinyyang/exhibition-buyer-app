-- 修复用户无法更新自己的 team_id 的问题
-- 问题：注册后用户创建了团队，但无法将自己的 team_id 更新为新团队的 ID
-- 原因：users 表的 UPDATE 策略过于严格，不允许用户修改 team_id 字段

-- 删除所有可能的旧策略（名称可能不一致）
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Users can update own data (not team_id)" ON users;

-- 创建新的更新策略：用户可以更新自己的所有字段（包括 team_id）
CREATE POLICY "Users can update own data"
  ON users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 注释：WITH CHECK 确保用户只能更新自己的记录，不能把自己的 ID 改成别人的
