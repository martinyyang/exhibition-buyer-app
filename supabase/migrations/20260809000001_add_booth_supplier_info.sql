-- 为 booths 表添加供应商信息字段
-- Migration: 20260809000001_add_booth_supplier_info.sql
-- Date: 2026-08-09

ALTER TABLE booths
ADD COLUMN IF NOT EXISTS supplier_name TEXT,
ADD COLUMN IF NOT EXISTS supplier_logo_url TEXT;

COMMENT ON COLUMN booths.supplier_name IS '供应商名称（可选）';
COMMENT ON COLUMN booths.supplier_logo_url IS '供应商Logo URL（可选）';
