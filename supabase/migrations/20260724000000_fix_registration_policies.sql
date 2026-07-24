-- 修复注册功能的 RLS 策略
-- 创建时间: 2026-07-24

-- 允许任何认证用户创建团队（注册时需要）
CREATE POLICY "Authenticated users can create teams"
  ON teams FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- 允许新注册用户插入自己的用户记录
CREATE POLICY "Users can insert own data"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- 允许团队成员查看同团队的其他成员信息（设置界面需要显示团队名称）
CREATE POLICY "Team members can view team members"
  ON users FOR SELECT
  USING (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );
