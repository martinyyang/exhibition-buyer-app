-- Add password field to teams table
-- This allows teams to set a password for retrieving invite codes

ALTER TABLE teams ADD COLUMN password TEXT;

-- Add comment explaining the column
COMMENT ON COLUMN teams.password IS 'Team password for invite code retrieval (stored in plain text for simplicity)';
