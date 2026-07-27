-- =====================================================
-- Supabase Storage 配置 - Photos Bucket
-- =====================================================
-- 执行此 SQL 创建 photos bucket 并配置访问策略

-- 1. 创建 photos bucket（如果不存在）
INSERT INTO storage.buckets (id, name, public)
VALUES ('photos', 'photos', true)
ON CONFLICT (id) DO NOTHING;

-- 2. 删除旧的 storage policies（如果存在）
DROP POLICY IF EXISTS "Team members can upload photos" ON storage.objects;
DROP POLICY IF EXISTS "Team members can view photos" ON storage.objects;
DROP POLICY IF EXISTS "Team members can delete photos" ON storage.objects;

-- 3. 允许团队成员上传照片
CREATE POLICY "Team members can upload photos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'photos'
  AND auth.uid() IS NOT NULL
  AND public.current_user_team_id() IS NOT NULL
);

-- 4. 允许团队成员查看照片（公开访问）
CREATE POLICY "Team members can view photos"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'photos'
);

-- 5. 允许团队成员删除自己团队的照片
CREATE POLICY "Team members can delete photos"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'photos'
  AND auth.uid() IS NOT NULL
  AND public.current_user_team_id() IS NOT NULL
);

-- =====================================================
-- 验证配置
-- =====================================================
-- 查看 bucket 配置
SELECT * FROM storage.buckets WHERE id = 'photos';

-- 查看 storage policies
SELECT * FROM pg_policies WHERE tablename = 'objects' AND policyname LIKE '%photos%';
