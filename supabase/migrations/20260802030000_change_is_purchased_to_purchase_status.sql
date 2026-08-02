-- Migration: Change is_purchased boolean to purchase_status string
-- This allows for more flexible purchase states: "Purchased", "sold out", or null

-- Add new column
ALTER TABLE flags ADD COLUMN IF NOT EXISTS purchase_status TEXT;

-- Migrate existing data: true -> "Purchased", false/null -> null
UPDATE flags SET purchase_status = 'Purchased' WHERE is_purchased = true;

-- Drop old column
ALTER TABLE flags DROP COLUMN IF EXISTS is_purchased;

-- Add constraint for valid values
ALTER TABLE flags ADD CONSTRAINT purchase_status_valid_values
  CHECK (purchase_status IS NULL OR purchase_status IN ('Purchased', 'sold out'));
