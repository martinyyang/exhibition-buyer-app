-- ============================================
-- 修复 create_team 函数的返回类型不匹配（2026-08-19）
-- ============================================
-- 问题: RETURNS TABLE 声明 created_at TIMESTAMPTZ，但 teams.created_at 实际是 TIMESTAMP
-- 错误: structure of query does not match function result type, code: 42804
-- 修复: 将返回类型改为 TIMESTAMP（不带时区），匹配实际表结构

CREATE OR REPLACE FUNCTION public.create_team(
  p_team_name TEXT,
  p_password TEXT
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  created_at TIMESTAMP,  -- 改为 TIMESTAMP（不带时区）
  creator_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_team_id UUID;
BEGIN
  -- 插入新团队，记录创建者
  INSERT INTO teams (name, password, creator_id)
  VALUES (p_team_name, p_password, auth.uid())
  RETURNING teams.id INTO v_team_id;

  -- 将当前用户关联到新团队
  UPDATE users
  SET team_id = v_team_id, is_team_creator = TRUE
  WHERE id = auth.uid();

  -- 返回团队信息
  RETURN QUERY
  SELECT teams.id, teams.name, teams.created_at, teams.creator_id
  FROM teams
  WHERE teams.id = v_team_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_team(TEXT, TEXT) TO authenticated;

COMMENT ON FUNCTION public.create_team IS '创建新团队并设置密码（返回类型匹配 TIMESTAMP）';
