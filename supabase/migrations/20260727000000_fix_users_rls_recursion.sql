-- 修复 users 表 RLS 策略的无限递归问题
-- 创建时间: 2026-07-27
-- 问题: "Team members can view team members" 策略在查询 users 表时又引用 users 表，导致无限递归

-- 1. 删除有问题的策略
DROP POLICY IF EXISTS "Team members can view team members" ON users;

-- 2. 创建修复后的策略（用户只能查看自己的记录）
CREATE POLICY "Users can view own data"
  ON users FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- 3. 如果需要查看团队成员信息，应该通过团队表关联，而不是在 users 表策略中递归查询
-- 注意：这个策略只允许用户查看自己的信息，如果需要查看团队其他成员，
-- 应该在应用层通过 teams 表的 RLS 策略来控制
