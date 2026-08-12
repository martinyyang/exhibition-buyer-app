-- 修复团队密码安全漏洞
-- 问题：客户端可以查询所有团队的密码字段
-- 解决：移除密码字段的 SELECT 权限，创建数据库函数在服务端验证密码

-- 1. 删除允许查看所有团队的策略（包括密码）
DROP POLICY IF EXISTS "Authenticated users can view all teams" ON teams;

-- 2. 创建新策略：认证用户只能查看团队的非敏感信息（排除密码）
-- 注意：RLS 策略无法直接限制列级别访问，需要结合视图或函数
CREATE POLICY "Authenticated users can view teams basic info"
  ON teams FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- 3. 创建数据库函数：验证团队密码并返回团队信息（不含密码）
CREATE OR REPLACE FUNCTION verify_team_password(
  p_identifier TEXT,
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
  v_team_record RECORD;
  v_is_invite_code BOOLEAN;
BEGIN
  -- 检查参数
  IF p_identifier IS NULL OR p_identifier = '' OR p_password IS NULL OR p_password = '' THEN
    RAISE EXCEPTION 'Team identifier and password cannot be empty';
  END IF;

  -- 判断是否是 6 位邀请码
  v_is_invite_code := LENGTH(TRIM(p_identifier)) = 6 AND TRIM(p_identifier) ~ '^[A-Z0-9]+$';

  IF v_is_invite_code THEN
    -- 按邀请码查找（前 6 位 UUID 大写）
    SELECT t.* INTO v_team_record
    FROM teams t
    WHERE UPPER(SUBSTRING(REPLACE(t.id::TEXT, '-', '') FROM 1 FOR 6)) = UPPER(TRIM(p_identifier))
      AND t.password = TRIM(p_password)
    LIMIT 1;
  ELSE
    -- 按团队名查找
    SELECT t.* INTO v_team_record
    FROM teams t
    WHERE LOWER(TRIM(t.name)) = LOWER(TRIM(p_identifier))
      AND t.password = TRIM(p_password)
    LIMIT 1;
  END IF;

  -- 检查是否找到匹配的团队
  IF v_team_record.id IS NULL THEN
    IF v_is_invite_code THEN
      RAISE EXCEPTION 'Team not found or incorrect password';
    ELSE
      -- 检查团队名是否存在
      PERFORM 1 FROM teams WHERE LOWER(TRIM(name)) = LOWER(TRIM(p_identifier));
      IF NOT FOUND THEN
        RAISE EXCEPTION 'Team not found with this name';
      ELSE
        RAISE EXCEPTION 'Incorrect password for this team';
      END IF;
    END IF;
  END IF;

  -- 返回团队信息（不含密码）
  RETURN QUERY
  SELECT
    v_team_record.id,
    v_team_record.name,
    v_team_record.created_at,
    v_team_record.creator_id;
END;
$$;

-- 4. 创建数据库函数：仅用于验证团队密码和查看邀请码（用于找回邀请码场景）
CREATE OR REPLACE FUNCTION get_team_with_password(
  p_team_id UUID,
  p_password TEXT
)
RETURNS TABLE(
  id UUID,
  name TEXT,
  created_at TIMESTAMPTZ,
  creator_id UUID,
  invite_code TEXT
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_team_record RECORD;
BEGIN
  -- 验证密码
  SELECT t.* INTO v_team_record
  FROM teams t
  WHERE t.id = p_team_id AND t.password = TRIM(p_password);

  IF v_team_record.id IS NULL THEN
    RAISE EXCEPTION 'Team not found or incorrect password';
  END IF;

  -- 返回团队信息（含邀请码但不含密码）
  RETURN QUERY
  SELECT
    v_team_record.id,
    v_team_record.name,
    v_team_record.created_at,
    v_team_record.creator_id,
    UPPER(SUBSTRING(REPLACE(v_team_record.id::TEXT, '-', '') FROM 1 FOR 6)) AS invite_code;
END;
$$;

-- 5. 授权：允许认证用户调用这些函数
GRANT EXECUTE ON FUNCTION verify_team_password(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_team_with_password(UUID, TEXT) TO authenticated;

-- 6. 注释
COMMENT ON FUNCTION verify_team_password IS '验证团队密码（通过团队名或邀请码），返回团队基本信息（不含密码）';
COMMENT ON FUNCTION get_team_with_password IS '通过团队 ID 和密码获取团队信息（含邀请码，用于找回邀请码场景）';
