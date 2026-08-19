-- ============================================
-- 修复 users 表 SELECT 权限缺失（2026-08-19）
-- ============================================
-- 问题：20260817000001_harden_team_security.sql 限制了 users.team_id 的 UPDATE 权限，
--       但未明确授予 SELECT 权限，导致生产环境登录后无法读取用户的 team_id。
-- 现象：路由逻辑依赖 currentUserDataProvider 获取 userTeamId，但 users 表查询
--       可能因列级权限缺失返回 null 或报错。
-- 修复：明确授予 authenticated 角色对 users 表所有列的 SELECT 权限。
-- ============================================

-- 撤销可能存在的部分列权限，统一重新授予
REVOKE SELECT ON users FROM authenticated;

-- 授予 users 表所有列的 SELECT 权限（用户需要读取自己和团队成员的完整信息）
GRANT SELECT ON users TO authenticated;

-- 确认 UPDATE 权限仍然只限于安全列（不包括 team_id）
-- team_id 只能通过 join_team / create_team RPC 修改
REVOKE UPDATE ON users FROM authenticated;
GRANT UPDATE (
  email,
  role,
  daily_color,
  color_assigned_date,
  last_seen,
  is_team_creator
) ON users TO authenticated;

-- 说明
COMMENT ON TABLE users IS '用户表：SELECT 全列开放，UPDATE 仅允许安全列（team_id 仅通过 RPC 修改）';
