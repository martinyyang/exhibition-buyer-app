-- Make team password required for security
-- Migration: 20260803000002_make_team_password_required.sql

-- First, set a default password for existing teams without password
UPDATE teams
SET password = 'LEGACY_TEAM_' || SUBSTRING(id::text, 1, 8)
WHERE password IS NULL OR password = '';

-- Now make the password field NOT NULL
ALTER TABLE teams
ALTER COLUMN password SET NOT NULL;

-- Add a comment explaining the change
COMMENT ON COLUMN teams.password IS 'Team password (required) - used for joining team and retrieving invite code';
