-- 诊断注册流程问题
-- 检查 RLS 策略是否阻止了 team_id 更新

-- 1. 查看所有用户及其 team_id
SELECT
  id,
  email,
  team_id,
  created_at,
  CASE
    WHEN team_id IS NULL THEN '❌ 缺少 team_id'
    ELSE '✅ 有 team_id'
  END as status
FROM users
ORDER BY created_at DESC;

-- 2. 查看所有团队
SELECT
  id,
  name,
  created_at,
  (SELECT COUNT(*) FROM users WHERE team_id = teams.id) as member_count
FROM teams
ORDER BY created_at DESC;

-- 3. 检查 users 表的 UPDATE 策略
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
WHERE tablename = 'users' AND cmd = 'UPDATE';

-- 4. 测试 UPDATE 权限（作为 service_role）
-- 注意：这个查询会实际修改数据，仅用于测试
-- 将最新的一个 team_id 为 null 的用户关联到 northpark 团队
-- UPDATE users
-- SET team_id = '16c02fee-54bc-48e7-b9a7-5993fc4f5bee'
-- WHERE team_id IS NULL
-- ORDER BY created_at DESC
-- LIMIT 1
-- RETURNING id, email, team_id;
