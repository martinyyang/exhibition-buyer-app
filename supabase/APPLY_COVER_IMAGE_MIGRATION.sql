-- ============================================================
-- MANUAL MIGRATION INSTRUCTIONS
-- ============================================================
--
-- This migration MUST be applied manually via Supabase Dashboard
-- because it was not applied when the feature was originally pushed.
--
-- Steps to apply:
-- 1. Go to: https://supabase.com/dashboard/project/ppwjblvnixqeympfcqgs
-- 2. Navigate to: SQL Editor
-- 3. Create a new query
-- 4. Copy and paste the SQL below
-- 5. Click "Run" to execute
--
-- ============================================================

-- 添加摊位封面图片字段
-- 创建时间: 2026-08-08

ALTER TABLE booths ADD COLUMN IF NOT EXISTS cover_image_url TEXT;

COMMENT ON COLUMN booths.cover_image_url IS '摊位封面图片URL（可选）';

-- ============================================================
-- VERIFICATION QUERY (run after the ALTER TABLE)
-- ============================================================
-- This should return the booth structure including cover_image_url

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'booths'
ORDER BY ordinal_position;
