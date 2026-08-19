-- ============================================
-- 修复 create_team 函数的 RECORD 列访问问题
-- ============================================
-- 问题: RETURNS TABLE 声明了列名，但 RETURN QUERY SELECT (v_team).id 无法识别 RECORD 类型中的列
-- 根因: PostgreSQL 在 RETURN QUERY 中无法直接访问 RECORD 类型的字段
-- 修复: 改用 INTO 变量存储各个字段，或直接 SELECT FROM teams

CREATE OR REPLACE FUNCTION public.create_team(
  p_name TEXT,
  p_password TEXT
)
RETURNS TABLE(
  id UUID,
  name TEXT,
  created_at TIMESTAMPTZ,
  creator_id UUID
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_team_id UUID;
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RAISE EXCEPTION 'Team name is required';
  END IF;
  IF p_password IS NULL OR TRIM(p_password) = '' THEN
    RAISE EXCEPTION 'Password is required';
  END IF;

  -- 插入团队并获取 ID
  INSERT INTO teams (name, password, creator_id)
  VALUES (TRIM(p_name), TRIM(p_password), auth.uid())
  RETURNING teams.id INTO v_team_id;

  -- 创建者自动加入团队
  UPDATE users SET team_id = v_team_id WHERE users.id = auth.uid();

  -- 直接从 teams 表查询返回完整数据
  RETURN QUERY
  SELECT teams.id, teams.name, teams.created_at, teams.creator_id
  FROM teams
  WHERE teams.id = v_team_id;
END;
$$;

COMMENT ON FUNCTION public.create_team(TEXT, TEXT) IS
'创建新团队并自动将创建者加入该团队。返回团队完整信息。';
