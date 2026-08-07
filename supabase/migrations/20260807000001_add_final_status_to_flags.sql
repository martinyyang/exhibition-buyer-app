-- Migration: Add final_status column to flags table
-- 添加"最终状态"字段，只有现场买手（buyer）可以修改

-- 添加 final_status 列
ALTER TABLE flags ADD COLUMN IF NOT EXISTS final_status TEXT;

-- 添加约束：只允许特定值
ALTER TABLE flags ADD CONSTRAINT final_status_valid_values
  CHECK (final_status IS NULL OR final_status IN ('购买', '已售', '放弃'));

-- 添加注释
COMMENT ON COLUMN flags.final_status IS '最终状态：只有现场买手可修改，选项为"购买"、"已售"、"放弃"';
COMMENT ON COLUMN flags.purchase_status IS '远程决策：只有远程团队可修改，选项为"Purchased"、"sold out"';
