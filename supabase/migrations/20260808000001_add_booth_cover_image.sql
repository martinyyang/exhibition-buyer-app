-- 添加摊位封面图片字段
-- 创建时间: 2026-08-08

ALTER TABLE booths ADD COLUMN cover_image_url TEXT;

COMMENT ON COLUMN booths.cover_image_url IS '摊位封面图片URL（可选）';
