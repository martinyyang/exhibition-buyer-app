-- ============================================
-- 修复生产端验证发现的问题（2026-08-17）
-- ============================================
-- 问题1: teams 表残留手动策略 "Users can view their team"（fix_rls_policies.js 曾引用，
--        但从未纳入迁移文件），叠加后任何认证用户可查看全部团队。
-- 修复: 清理全部历史 SELECT 策略名并重建 "Users can view own teams"。
--
-- 问题2: create_team 调用报 42702 "column reference id is ambiguous"。
--        根因: RETURNS TABLE(id, name, created_at, creator_id) 的输出参数在函数体内
--        成为可见变量，与 INSERT RETURNING 裸列名冲突；join_team 的
--        UPDATE ... WHERE id = auth.uid() 同样存在裸 id 歧义（会静默失效）。
-- 修复: RECORD 字段访问加括号消除歧义；UPDATE 的 id 条件用 users.id 表名限定。
-- ============================================

-- ============================================
-- 1. teams SELECT 策略清理 + 重建
-- ============================================
DROP POLICY IF EXISTS "Users can view their team" ON teams;
DROP POLICY IF EXISTS "Users can view own teams" ON teams;
DROP POLICY IF EXISTS "Team members can view team" ON teams;
DROP POLICY IF EXISTS "Authenticated users can view all teams" ON teams;
DROP POLICY IF EXISTS "Authenticated users can view teams basic info" ON teams;

CREATE POLICY "Users can view own teams"
  ON teams FOR SELECT
  USING (id = public.current_user_team_id());

COMMENT ON POLICY "Users can view own teams" ON teams IS
'用户只能查看自己所在团队的基本信息（加入团队通过 join_team RPC 完成）';

-- ============================================
-- 2. users 表历史残留策略清理
-- （保留: "Users can view own data" / "Users can update own data" /
--         "Users can insert own data" / "Team members can view team members"）
-- ============================================
DROP POLICY IF EXISTS "Users can view their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Service role full access" ON users;

-- ============================================
-- 3. create_team：修复 INSERT RETURNING 输出参数歧义（42702）
-- ============================================
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
  v_team RECORD;
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RAISE EXCEPTION 'Team name is required';
  END IF;
  IF p_password IS NULL OR TRIM(p_password) = '' THEN
    RAISE EXCEPTION 'Password is required';
  END IF;

  INSERT INTO teams (name, password, creator_id)
  VALUES (TRIM(p_name), TRIM(p_password), auth.uid())
  RETURNING * INTO v_team;

  -- 创建者自动加入团队（users.id 表名限定，避免与输出参数 id 歧义）
  UPDATE users SET team_id = (v_team).id WHERE users.id = auth.uid();

  RETURN QUERY
  SELECT (v_team).id, (v_team).name, (v_team).created_at, (v_team).creator_id;
END;
$$;

-- ============================================
-- 4. join_team：修复 UPDATE 条件中裸 id 的歧义
-- ============================================
CREATE OR REPLACE FUNCTION public.join_team(
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
  v_team RECORD;
BEGIN
  IF p_identifier IS NULL OR TRIM(p_identifier) = ''
     OR p_password IS NULL OR TRIM(p_password) = '' THEN
    RAISE EXCEPTION 'Team identifier and password cannot be empty';
  END IF;

  SELECT t.id, t.name, t.created_at, t.creator_id INTO v_team
  FROM teams t
  WHERE (
        UPPER(SUBSTRING(REPLACE(t.id::TEXT, '-', '') FROM 1 FOR 6)) = UPPER(TRIM(p_identifier))
     OR LOWER(TRIM(t.name)) = LOWER(TRIM(p_identifier))
  )
    AND t.password = TRIM(p_password)
  LIMIT 1;

  IF v_team.id IS NULL THEN
    RAISE EXCEPTION 'Team not found or incorrect password';
  END IF;

  -- users.id 表名限定，避免与输出参数 id 歧义
  UPDATE users SET team_id = (v_team).id WHERE users.id = auth.uid();

  RETURN QUERY
  SELECT (v_team).id, (v_team).name, (v_team).created_at, (v_team).creator_id;
END;
$$;

-- ============================================
-- 5. verify_team_password：统一括号语法（防同类歧义）
-- ============================================
CREATE OR REPLACE FUNCTION public.verify_team_password(
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
BEGIN
  IF p_identifier IS NULL OR p_identifier = '' OR p_password IS NULL OR p_password = '' THEN
    RAISE EXCEPTION 'Team identifier and password cannot be empty';
  END IF;

  SELECT t.* INTO v_team_record
  FROM teams t
  WHERE (
        UPPER(SUBSTRING(REPLACE(t.id::TEXT, '-', '') FROM 1 FOR 6)) = UPPER(TRIM(p_identifier))
     OR LOWER(TRIM(t.name)) = LOWER(TRIM(p_identifier))
  )
    AND t.password = TRIM(p_password)
  LIMIT 1;

  IF v_team_record.id IS NULL THEN
    RAISE EXCEPTION 'Team not found or incorrect password';
  END IF;

  RETURN QUERY
  SELECT
    (v_team_record).id,
    (v_team_record).name,
    (v_team_record).created_at,
    (v_team_record).creator_id;
END;
$$;
