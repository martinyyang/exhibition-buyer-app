-- Fix formula_history RLS policies
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Team members can view formula history" ON formula_history;
DROP POLICY IF EXISTS "Team members can insert formula history" ON formula_history;
DROP POLICY IF EXISTS "Team members can update formula history" ON formula_history;

-- Recreate policies with proper checks
CREATE POLICY "Team members can view formula history"
  ON formula_history FOR SELECT
  USING (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid() AND team_id IS NOT NULL
    )
  );

CREATE POLICY "Team members can insert formula history"
  ON formula_history FOR INSERT
  WITH CHECK (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid() AND team_id IS NOT NULL
    )
  );

CREATE POLICY "Team members can update formula history"
  ON formula_history FOR UPDATE
  USING (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid() AND team_id IS NOT NULL
    )
  );

-- Add comment
COMMENT ON TABLE formula_history IS 'Stores formula usage history for teams with RLS enabled';
