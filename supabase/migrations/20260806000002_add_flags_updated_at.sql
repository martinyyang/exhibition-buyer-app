-- Add updated_at column to flags table for conflict detection
ALTER TABLE flags ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Create index for performance
CREATE INDEX idx_flags_updated_at ON flags(updated_at);

-- Create trigger to automatically update updated_at on row changes
CREATE OR REPLACE FUNCTION update_flags_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_flags_updated_at
  BEFORE UPDATE ON flags
  FOR EACH ROW
  EXECUTE FUNCTION update_flags_updated_at();

-- Backfill updated_at with created_at for existing rows
UPDATE flags SET updated_at = created_at WHERE updated_at IS NULL;
