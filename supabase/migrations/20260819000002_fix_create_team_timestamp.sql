-- 修复 create_team 函数的返回类型，匹配 teams 表的实际 timestamp 类型（不带时区）
-- 根因：函数声明 TIMESTAMPTZ 但表列是 TIMESTAMP，导致 PostgreSQL 类型不匹配错误 42804

-- 必须先删除旧函数（PostgreSQL 不允许直接修改返回类型）
DROP FUNCTION IF EXISTS create_team(TEXT, TEXT, UUID);

-- 重新创建函数，使用正确的返回类型
CREATE FUNCTION create_team(
  p_team_name TEXT,
  p_password TEXT,
  p_user_id UUID
)
RETURNS TABLE(
  team_id UUID,
  team_name TEXT,
  created_at TIMESTAMP  -- 改为 TIMESTAMP（原来是 TIMESTAMPTZ）
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_team_id UUID;
BEGIN
  -- 创建团队
  INSERT INTO teams (name, password)
  VALUES (p_team_name, p_password)
  RETURNING id INTO v_team_id;

  -- 更新用户的 team_id
  UPDATE users
  SET team_id = v_team_id
  WHERE id = p_user_id;

  -- 返回团队信息
  RETURN QUERY
  SELECT id, name, created_at
  FROM teams
  WHERE id = v_team_id;
END;
$$;
