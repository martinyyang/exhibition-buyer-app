-- ============================================
-- 照片功能一键配置 SQL
-- 复制全部内容到 Supabase SQL Editor 并执行
-- ============================================

-- 第一步：创建 Storage Bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('photos', 'photos', true)
ON CONFLICT (id) DO NOTHING;

-- 第二步：配置 Storage 策略
DROP POLICY IF EXISTS "Team members can upload photos" ON storage.objects;
DROP POLICY IF EXISTS "Team members can view photos" ON storage.objects;
DROP POLICY IF EXISTS "Team members can delete photos" ON storage.objects;

CREATE POLICY "Team members can upload photos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'photos'
  AND auth.uid() IN (
    SELECT id FROM public.users WHERE team_id = public.current_user_team_id()
  )
);

CREATE POLICY "Team members can view photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'photos');

CREATE POLICY "Team members can delete photos"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'photos'
  AND auth.uid() IN (
    SELECT id FROM public.users WHERE team_id = public.current_user_team_id()
  )
);

-- 第三步：启用 Realtime（确保照片上传后自动刷新）
ALTER PUBLICATION supabase_realtime ADD TABLE photos;

-- 第四步：配置 Photos 表 RLS
DROP POLICY IF EXISTS "Team members can view photos" ON photos;
DROP POLICY IF EXISTS "Team members can insert photos" ON photos;
DROP POLICY IF EXISTS "Team members can delete photos" ON photos;

CREATE POLICY "Team members can view photos"
ON photos FOR SELECT
USING (
  booth_id IN (
    SELECT b.id FROM booths b
    JOIN events e ON b.event_id = e.id
    WHERE e.team_id = public.current_user_team_id()
  )
);

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

CREATE POLICY "Team members can delete photos"
ON photos FOR DELETE
USING (
  booth_id IN (
    SELECT b.id FROM booths b
    JOIN events e ON b.event_id = e.id
    WHERE e.team_id = public.current_user_team_id()
  )
);

-- 完成！现在可以上传照片了
-- 注意：照片上传后会自动显示在列表中（Realtime 实时同步）
