-- 紧急修复：清理并重建 users 表的 UPDATE 策略
-- 问题：生产环境中存在策略冲突，导致 team_id 无法更新
-- 创建时间: 2026-08-05

-- 删除所有可能存在的 UPDATE 策略
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Users can update own data (not team_id)" ON users;

-- 创建唯一的 UPDATE 策略
CREATE POLICY "Users can update own data"
  ON users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 添加注释
COMMENT ON POLICY "Users can update own data" ON users IS
'允许用户更新自己的所有字段，包括 team_id、role、daily_color 等。USING 和 WITH CHECK 都验证 auth.uid() = id，确保用户只能修改自己的记录。';
