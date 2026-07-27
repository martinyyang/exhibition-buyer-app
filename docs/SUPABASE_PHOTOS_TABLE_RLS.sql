-- =====================================================
-- Supabase RLS 配置 - Photos 表
-- =====================================================
-- 执行此 SQL 配置 photos 表的行级安全策略

-- 1. 启用 RLS
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;

-- 2. 删除旧的 photos 策略（如果存在）
DROP POLICY IF EXISTS "Team members can insert photos" ON photos;
DROP POLICY IF EXISTS "Team members can view photos" ON photos;
DROP POLICY IF EXISTS "Team members can update photos" ON photos;
DROP POLICY IF EXISTS "Team members can delete photos" ON photos;

-- 3. 查看照片 - 通过 booth_id -> event_id -> team_id 关联
CREATE POLICY "Team members can view photos"
ON photos FOR SELECT
USING (
  booth_id IN (
    SELECT b.id FROM booths b
    JOIN events e ON b.event_id = e.id
    WHERE e.team_id = public.current_user_team_id()
  )
);

-- 4. 插入照片 - 验证 booth 属于当前团队
CREATE POLICY "Team members can insert photos"
ON photos FOR INSERT
WITH CHECK (
  booth_id IN (
    SELECT b.id FROM booths b
    JOIN events e ON b.event_id = e.id
    WHERE e.team_id = public.current_user_team_id()
  )
  AND public.current_user_team_id() IS NOT NULL
);

-- 5. 更新照片（供应商信息）
CREATE POLICY "Team members can update photos"
ON photos FOR UPDATE
USING (
  booth_id IN (
    SELECT b.id FROM booths b
    JOIN events e ON b.event_id = e.id
    WHERE e.team_id = public.current_user_team_id()
  )
);

-- 6. 删除照片
CREATE POLICY "Team members can delete photos"
ON photos FOR DELETE
USING (
  booth_id IN (
    SELECT b.id FROM booths b
    JOIN events e ON b.event_id = e.id
    WHERE e.team_id = public.current_user_team_id()
  )
);

-- =====================================================
-- 验证配置
-- =====================================================
-- 查看 photos 表的 RLS 策略
SELECT * FROM pg_policies WHERE tablename = 'photos';
