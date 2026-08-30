-- ============================================================
-- 综合修复迁移：加入队伍功能 bug + teams RLS 安全告警
-- 2026-08-30
-- 目标库：PostgreSQL 14（注意：不支持 security_invoker 视图属性）
-- ============================================================

-- ========== 1. 修复 join_team 返回类型（功能 bug：用户无法加入队伍） ==========
-- 根因：函数声明返回 created_at timestamp with time zone，
--       但 teams.created_at 实际是 timestamp without time zone，
--       RETURN QUERY 时类型不匹配 → 报错 42804（与 create_team 历史 bug 同款，
--       join_team 一直未被修复）。创建团队正常、加入团队报错。
-- 修复：DROP + CREATE（PostgreSQL 不允许 REPLACE 修改返回类型），返回类型对齐 teams 表。
DROP FUNCTION IF EXISTS public.join_team(text, text);

CREATE FUNCTION public.join_team(p_identifier text, p_password text)
 RETURNS TABLE(id uuid, name text, created_at timestamp without time zone, creator_id uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$;

-- 恢复执行权限（DROP 会清除 GRANT）
GRANT EXECUTE ON FUNCTION public.join_team(text, text) TO anon, authenticated, service_role;

-- ========== 2. 启用 teams 表 RLS（安全告警 Critical） ==========
-- 该表已有 INSERT/SELECT 策略，启用后立即生效；
-- 创建/加入团队/密码验证走 SECURITY DEFINER RPC，不受 RLS 影响。
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

-- 补充 UPDATE 策略：团队成员可更新自己的团队（settings 改名依赖，防止锁死）
CREATE POLICY "Team members can update own team"
ON public.teams
FOR UPDATE
TO public
USING (id = current_user_team_id())
WITH CHECK (id = current_user_team_id());

-- ========== 3. 移除 SECURITY DEFINER 越权视图 photo_details ==========
-- 该视图 SECURITY DEFINER，登录用户可跨团队看到所有照片/旗子汇总；
-- 应用当前未引用（历史遗留）。PG14 不支持 security_invoker，
-- 直接删除以消除越权点。如未来需要，可按下述定义重建（SECURITY INVOKER 版需 PG15+，
-- PG14 下需配合 RLS 策略约束）。
DROP VIEW IF EXISTS public.photo_details;
