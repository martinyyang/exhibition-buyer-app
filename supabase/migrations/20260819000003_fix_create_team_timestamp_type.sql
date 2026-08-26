-- ============================================
-- 修复 create_team 函数的返回类型不匹配（2026-08-19 创建 / 2026-08-21 修订）
-- ============================================
-- 报错: structure of query does not match function result type, code: 42804
-- 详情: Returned type timestamp without time zone does not match expected
--       type timestamp with time zone in column 3
--
-- 根因（三层）:
--   1. 函数 RETURNS TABLE 声明 created_at TIMESTAMPTZ（20260817000001 版），
--      但 teams.created_at 实际是 TIMESTAMP（不带时区）→ 返回类型不匹配 42804。
--   2. 本迁移早期版本用 CREATE OR REPLACE 修改返回类型 —— PostgreSQL 不允许
--      用 REPLACE 修改已有函数的返回类型（cannot change return type of
--      existing function），因此该迁移在生产库要么未应用、要么应用即失败，
--      线上函数一直是 TIMESTAMPTZ 版本。
--      正确做法: 先 DROP 旧函数，再 CREATE（本文件已改为该方式，幂等）。
--   3. 参数名必须与客户端一致：PostgREST 按参数名匹配 JSON 参数，
--      lib/features/team/services/team_service.dart 传 p_name / p_password，
--      因此函数参数必须命名为 p_name（不能用 p_team_name）。
--   4. 生产库可能存在多个 create_team 重载（如 20260819000002_timestamp 遗留的
--      三参数版 create_team(TEXT,TEXT,UUID)），此时不带参数列表的语句
--      （如 COMMENT ON FUNCTION public.create_team IS ...）会报 42725
--      "function name is not unique"。
--      处理: 所有引用都带参数列表，并清理遗留的三参数版。

-- 清理历史遗留的三参数重载（客户端只调用两参数版，无依赖）
DROP FUNCTION IF EXISTS public.create_team(TEXT, TEXT, UUID);

-- 必须先删除旧函数（PostgreSQL 不允许直接修改返回类型）
DROP FUNCTION IF EXISTS public.create_team(TEXT, TEXT);

CREATE FUNCTION public.create_team(
  p_name TEXT,
  p_password TEXT
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  created_at TIMESTAMP,  -- 改为 TIMESTAMP（不带时区），匹配 teams.created_at 实际类型
  creator_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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

  -- 插入新团队，记录创建者
  INSERT INTO teams (name, password, creator_id)
  VALUES (TRIM(p_name), TRIM(p_password), auth.uid())
  RETURNING teams.id INTO v_team_id;

  -- 将当前用户关联到新团队并标记为创建者
  -- 注意: WHERE 必须限定 users.id —— 未限定名 id 会与 RETURNS TABLE 输出参数冲突，
  -- PostgreSQL 报 column reference "id" is ambiguous（真实 PG14 验证）
  UPDATE users
  SET team_id = v_team_id, is_team_creator = TRUE
  WHERE users.id = auth.uid();

  -- 返回团队信息
  RETURN QUERY
  SELECT teams.id, teams.name, teams.created_at, teams.creator_id
  FROM teams
  WHERE teams.id = v_team_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_team(TEXT, TEXT) TO authenticated;

COMMENT ON FUNCTION public.create_team(TEXT, TEXT) IS '创建新团队并设置密码（返回类型匹配 TIMESTAMP，参数名 p_name/p_password 对齐客户端）';
