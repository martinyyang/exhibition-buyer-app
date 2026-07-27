-- 修复 users 表 RLS 策略的无限递归问题
-- 执行方式：在 Supabase Dashboard SQL Editor 中运行

-- 1. 删除有问题的策略
DROP POLICY IF EXISTS "Team members can view team members" ON users;

-- 2. 创建修复后的策略（用户只能查看自己的记录）
CREATE POLICY "Users can view own data"
  ON users FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- 完成！刷新网页测试
