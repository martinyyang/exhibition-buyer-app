-- 修复注册后团队关联问题
-- 问题：注册后创建事件时报错 "User is not part of a team"

-- 1. 验证 users 表的更新策略允许用户更新自己的 team_id
-- 应该已经存在这个策略：
-- CREATE POLICY "Users can update own data"
--   ON users FOR UPDATE
--   USING (auth.uid() = id);

-- 2. 验证 events 表的插入策略正确
-- 当前策略要求 team_id 必须匹配用户的 team_id
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename IN ('users', 'events', 'teams')
ORDER BY tablename, policyname;

-- 3. 检查是否有用户的 team_id 为 NULL
SELECT
  id,
  email,
  role,
  team_id,
  created_at
FROM users
WHERE team_id IS NULL;
