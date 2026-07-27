-- 🔧 Realtime 实时同步修复
--
-- 问题：照片上传成功但不显示
-- 原因：photos 表未启用 Realtime 发布
-- 解决：将 photos 表添加到 supabase_realtime 发布中
--
-- ⚠️ 请在 Supabase Dashboard SQL Editor 中执行此命令

ALTER PUBLICATION supabase_realtime ADD TABLE photos;

-- 验证是否成功（可选）：
-- SELECT schemaname, tablename
-- FROM pg_publication_tables
-- WHERE pubname = 'supabase_realtime';
--
-- 应该看到 photos 表出现在结果中
