-- Migration: 修复团队密码验证函数 + flags.final_status 列（修正版）
-- 问题：
--   1. verify_team_password 返回 created_at TIMESTAMPTZ，但 teams.created_at 是 TIMESTAMP WITHOUT TIME ZONE
--      → 一旦匹配到行即报 42804（column "created_at" is of type timestamp without time zone but expression is of type timestamp with time zone）
--      → 返回类型改动需先 DROP（42P13: cannot change return type of existing function）
--   2. get_team_with_password 函数不存在，但应用 team_service.dart 调用它（RPC 404 → 查看邀请码功能静默失败）
--   3. flags.final_status 列缺失（现场买手最终成交状态：购买/已售/放弃）
--
-- 执行方式：Supabase Dashboard → SQL Editor → 粘贴本文件全部内容 → Run
-- 幂等：可重复执行（已建的对象不会报错，重复 DROP+CREATE 也安全）

-- ========== 1. 修复 verify_team_password：先 DROP 再 CREATE（返回类型与 teams.created_at 对齐） ==========
DROP FUNCTION IF EXISTS public.verify_team_password(text, text);

CREATE FUNCTION public.verify_team_password(p_identifier text, p_password text)
 RETURNS TABLE(id uuid, name text, created_at timestamp without time zone, creator_id uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  SELECT (v_team_record).id, (v_team_record).name, (v_team_record).created_at, (v_team_record).creator_id;
END;
$function$;

-- ========== 2. 创建应用实际调用的 get_team_with_password ==========
-- 应用 team_service.dart:69 调用 rpc('get_team_with_password', {p_team_id, p_password})
-- p_team_id 同时支持 UUID 或 6 位邀请码
CREATE OR REPLACE FUNCTION public.get_team_with_password(p_team_id text, p_password text)
 RETURNS TABLE(id uuid, name text, created_at timestamp without time zone, creator_id uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_team RECORD;
BEGIN
  IF p_team_id IS NULL OR TRIM(p_team_id) = '' OR p_password IS NULL OR TRIM(p_password) = '' THEN
    RAISE EXCEPTION 'Team id and password cannot be empty';
  END IF;

  SELECT t.id, t.name, t.created_at, t.creator_id INTO v_team
  FROM teams t
  WHERE (t.id::TEXT = TRIM(p_team_id)
      OR UPPER(SUBSTRING(REPLACE(t.id::TEXT, '-', '') FROM 1 FOR 6)) = UPPER(TRIM(p_team_id)))
    AND t.password = TRIM(p_password)
  LIMIT 1;

  IF v_team.id IS NULL THEN
    RAISE EXCEPTION 'Team not found or incorrect password';
  END IF;

  RETURN QUERY SELECT (v_team).id, (v_team).name, (v_team).created_at, (v_team).creator_id;
END;
$function$;

-- 授权认证用户调用
GRANT EXECUTE ON FUNCTION public.verify_team_password(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_team_with_password(text, text) TO authenticated;

-- ========== 3. flags 表增加 final_status 列（现场买手最终成交状态） ==========
ALTER TABLE flags ADD COLUMN IF NOT EXISTS final_status TEXT;
ALTER TABLE flags DROP CONSTRAINT IF EXISTS final_status_valid_values;
ALTER TABLE flags ADD CONSTRAINT final_status_valid_values
  CHECK (final_status IS NULL OR final_status IN ('购买', '已售', '放弃'));
COMMENT ON COLUMN flags.final_status IS '最终状态：只有现场买手可修改，选项为"购买"、"已售"、"放弃"';
