-- Migration: 修复团队函数 RECORD 列引用错误（42703）
-- 问题：join_team / verify_team_password / get_team_with_password 内部用 `v_team RECORD`，
--       RETURN QUERY 中引用 (v_team).id 时 PostgreSQL 报
--       "could not identify column \"id\" in record data type" (42703)
--       → 用户无法加入团队（应用侧报 PostgresException 42703）
-- 解决：把 RECORD 变量改为明确的 teams%ROWTYPE，RETURN QUERY 直接引用行类型列。
-- 三个函数的返回类型均未改变，可直接 CREATE OR REPLACE（无需 DROP）。
--
-- 执行方式：Supabase Dashboard → SQL Editor → 粘贴本文件全部内容 → Run（预期 Success. No rows returned）

-- ========== 1. join_team（加入团队） ==========
CREATE OR REPLACE FUNCTION public.join_team(p_identifier text, p_password text)
 RETURNS TABLE(id uuid, name text, created_at timestamp without time zone, creator_id uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_team teams%ROWTYPE;
BEGIN
  IF p_identifier IS NULL OR TRIM(p_identifier) = '' OR p_password IS NULL OR TRIM(p_password) = '' THEN
    RAISE EXCEPTION 'Team identifier and password cannot be empty';
  END IF;

  SELECT t.* INTO v_team
  FROM teams t
  WHERE (UPPER(SUBSTRING(REPLACE(t.id::TEXT,'-','') FROM 1 FOR 6)) = UPPER(TRIM(p_identifier))
      OR LOWER(TRIM(t.name)) = LOWER(TRIM(p_identifier)))
    AND t.password = TRIM(p_password)
  LIMIT 1;

  IF v_team.id IS NULL THEN
    RAISE EXCEPTION 'Team not found or incorrect password';
  END IF;

  UPDATE users SET team_id = v_team.id WHERE users.id = auth.uid();
  RETURN QUERY SELECT v_team.id, v_team.name, v_team.created_at, v_team.creator_id;
END;
$function$;

-- ========== 2. verify_team_password（校验密码/邀请码） ==========
CREATE OR REPLACE FUNCTION public.verify_team_password(p_identifier text, p_password text)
 RETURNS TABLE(id uuid, name text, created_at timestamp without time zone, creator_id uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_team_record teams%ROWTYPE;
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
  SELECT v_team_record.id, v_team_record.name, v_team_record.created_at, v_team_record.creator_id;
END;
$function$;

-- ========== 3. get_team_with_password（应用查看邀请码实际调用） ==========
CREATE OR REPLACE FUNCTION public.get_team_with_password(p_team_id text, p_password text)
 RETURNS TABLE(id uuid, name text, created_at timestamp without time zone, creator_id uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_team teams%ROWTYPE;
BEGIN
  IF p_team_id IS NULL OR TRIM(p_team_id) = '' OR p_password IS NULL OR TRIM(p_password) = '' THEN
    RAISE EXCEPTION 'Team id and password cannot be empty';
  END IF;

  SELECT t.* INTO v_team
  FROM teams t
  WHERE (t.id::TEXT = TRIM(p_team_id)
      OR UPPER(SUBSTRING(REPLACE(t.id::TEXT, '-', '') FROM 1 FOR 6)) = UPPER(TRIM(p_team_id)))
    AND t.password = TRIM(p_password)
  LIMIT 1;

  IF v_team.id IS NULL THEN
    RAISE EXCEPTION 'Team not found or incorrect password';
  END IF;

  RETURN QUERY SELECT v_team.id, v_team.name, v_team.created_at, v_team.creator_id;
END;
$function$;

-- 授权保持
GRANT EXECUTE ON FUNCTION public.verify_team_password(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_team_with_password(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.join_team(text, text) TO authenticated;
