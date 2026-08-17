-- ============================================
-- 团队数据安全加固（2026-08-17）
-- ============================================
-- 修复两个 CRITICAL 漏洞 + 补齐版本控制缺口：
--
-- 漏洞1: teams.password（明文）可被所有认证用户 SELECT 读取
--   根因: RLS 行策略（auth.uid() IS NOT NULL）只控制行，不控制列；
--         Supabase 默认授予 authenticated 表级 SELECT 权限。
--   修复: 列级权限收缩 —— authenticated 不再拥有 password 列的任何权限。
--
-- 漏洞2: 任意认证用户可绕过密码验证，直接修改自己的 team_id 加入任意团队
--   根因: users 表 UPDATE 策略允许用户修改自己记录的所有字段（含 team_id）；
--         结合漏洞1 可枚举所有团队 ID。
--   修复: 撤销 users.team_id 列的客户端 UPDATE 权限；
--         新增 SECURITY DEFINER RPC（join_team / create_team），
--         在服务端校验密码后原子地设置 team_id。
--
-- 版本控制缺口: teams.creator_id、users.last_seen、public.current_user_team_id()
--   此前在生产库手动创建但从未纳入迁移文件，新环境部署会失败。此处幂等补齐。
-- ============================================

-- ============================================
-- 0. 补齐缺失的 schema 定义（幂等）
-- ============================================
ALTER TABLE teams
  ADD COLUMN IF NOT EXISTS creator_id UUID REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE;

-- ============================================
-- 1. current_user_team_id() —— RLS 策略引用的安全函数（SECURITY DEFINER 绕过 RLS）
-- ============================================
CREATE OR REPLACE FUNCTION public.current_user_team_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT team_id FROM public.users WHERE id = auth.uid();
$$;

GRANT EXECUTE ON FUNCTION public.current_user_team_id() TO authenticated;

-- ============================================
-- 2. teams 表列级权限收缩（漏洞1 的根本修复）
-- ============================================
REVOKE ALL ON teams FROM authenticated;

-- SELECT: 仅非敏感列（不含 password）
GRANT SELECT (id, name, created_at, creator_id) ON teams TO authenticated;
-- UPDATE: 仅团队名（不允许修改密码）
GRANT UPDATE (name) ON teams TO authenticated;
-- 不再授予 INSERT：团队创建统一走 create_team RPC

-- ============================================
-- 3. teams SELECT 行策略：仅允许查看自己所在的团队（阻断团队 ID 枚举）
-- ============================================
DROP POLICY IF EXISTS "Authenticated users can view teams basic info" ON teams;
DROP POLICY IF EXISTS "Authenticated users can view all teams" ON teams;
DROP POLICY IF EXISTS "Team members can view team" ON teams;

CREATE POLICY "Users can view own teams"
  ON teams FOR SELECT
  USING (id = public.current_user_team_id());

COMMENT ON POLICY "Users can view own teams" ON teams IS
'用户只能查看自己所在团队的基本信息（加入团队通过 join_team RPC 完成，无需浏览全部团队）';

-- ============================================
-- 4. users 表列级权限收缩（漏洞2 的根本修复）
-- ============================================
-- 撤销 team_id 的直接修改能力；保留日常可更新列
REVOKE UPDATE ON users FROM authenticated;
GRANT UPDATE (
  email,
  role,
  daily_color,
  color_assigned_date,
  last_seen,
  is_team_creator
) ON users TO authenticated;

-- ============================================
-- 5. join_team RPC：服务端验证密码 + 设置 team_id（原子，防绕过）
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

  -- 支持 6 位邀请码（UUID 前 6 位大写）或团队名匹配，均需密码校验
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

  -- 原子设置 team_id（SECURITY DEFINER，不受 users 列级权限限制）
  UPDATE users SET team_id = v_team.id WHERE id = auth.uid();

  RETURN QUERY
  SELECT v_team.id, v_team.name, v_team.created_at, v_team.creator_id;
END;
$$;

-- ============================================
-- 6. create_team RPC：创建团队 + 设置创建者 + 加入团队（原子）
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
  RETURNING id, name, created_at, creator_id INTO v_team;

  -- 创建者自动加入团队
  UPDATE users SET team_id = v_team.id WHERE id = auth.uid();

  RETURN QUERY
  SELECT v_team.id, v_team.name, v_team.created_at, v_team.creator_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.join_team(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_team(TEXT, TEXT) TO authenticated;

-- ============================================
-- 7. verify_team_password：统一错误消息，消除团队名枚举
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

  -- 支持 6 位邀请码或团队名，统一失败消息防止团队名枚举
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
    v_team_record.id,
    v_team_record.name,
    v_team_record.created_at,
    v_team_record.creator_id;
END;
$$;

-- ============================================
-- 8. 说明文档
-- ============================================
COMMENT ON FUNCTION public.join_team IS '验证团队密码（团队名或邀请码）并原子地将当前用户加入团队';
COMMENT ON FUNCTION public.create_team IS '创建团队并将当前用户设为创建者并加入团队';
COMMENT ON FUNCTION public.current_user_team_id IS '获取当前认证用户的团队 ID（SECURITY DEFINER，供 RLS 策略使用）';
COMMENT ON COLUMN teams.creator_id IS '团队创建者（第一个加入的成员）';
COMMENT ON COLUMN users.last_seen IS '用户最后活跃时间';
