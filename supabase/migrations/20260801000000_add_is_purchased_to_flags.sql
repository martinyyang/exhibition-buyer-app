-- Add is_purchased column to flags table
ALTER TABLE flags
ADD COLUMN IF NOT EXISTS is_purchased BOOLEAN DEFAULT false NOT NULL;

-- Add comment to the column
COMMENT ON COLUMN flags.is_purchased IS 'Indicates whether the product has been purchased';

-- Create index for faster queries on purchased flags
CREATE INDEX IF NOT EXISTS idx_flags_is_purchased ON flags(is_purchased);
