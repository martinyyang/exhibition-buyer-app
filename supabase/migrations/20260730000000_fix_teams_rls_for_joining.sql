-- 修复teams表的RLS策略，允许所有认证用户查看所有团队（用于加入团队）
-- 问题: 当前策略只允许查看"自己已加入的团队"，导致team_id为NULL的用户无法查询任何团队
-- 解决: 添加新策略允许所有认证用户查看所有团队列表

-- 删除旧的限制性策略
DROP POLICY IF EXISTS "Team members can view team" ON teams;

-- 添加新策略：所有认证用户都可以查看所有团队（用于浏览和加入）
CREATE POLICY "Authenticated users can view all teams"
  ON teams FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- 添加策略：所有认证用户都可以创建团队
CREATE POLICY "Authenticated users can create teams"
  ON teams FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- 添加策略：团队成员可以更新自己的团队信息
CREATE POLICY "Team members can update own team"
  ON teams FOR UPDATE
  USING (
    id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );
