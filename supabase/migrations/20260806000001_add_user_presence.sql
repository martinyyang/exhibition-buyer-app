-- 添加用户在线状态表
-- 创建时间: 2026-08-06

-- 用户在线状态表
CREATE TABLE user_presence (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('online', 'offline')),
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  current_screen TEXT, -- 当前所在页面 (如 'photo_detail', 'booth_list')
  current_context JSONB, -- 当前页面上下文 (如 {"photo_id": "xxx", "booth_id": "yyy"})
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引以提高查询性能
CREATE INDEX idx_user_presence_team_id ON user_presence(team_id);
CREATE INDEX idx_user_presence_status ON user_presence(status);
CREATE INDEX idx_user_presence_updated_at ON user_presence(updated_at);

-- RLS 策略：只能查看同团队成员的在线状态
ALTER TABLE user_presence ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view team presence"
  ON user_presence FOR SELECT
  USING (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can update own presence"
  ON user_presence FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own presence"
  ON user_presence FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own presence"
  ON user_presence FOR DELETE
  USING (user_id = auth.uid());

-- 自动更新 updated_at 时间戳的触发器
CREATE OR REPLACE FUNCTION update_user_presence_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_presence_updated_at
  BEFORE UPDATE ON user_presence
  FOR EACH ROW
  EXECUTE FUNCTION update_user_presence_timestamp();

-- 自动清理离线超过 5 分钟的用户状态
CREATE OR REPLACE FUNCTION cleanup_stale_presence()
RETURNS void AS $$
BEGIN
  UPDATE user_presence
  SET status = 'offline'
  WHERE status = 'online'
    AND updated_at < NOW() - INTERVAL '5 minutes';
END;
$$ LANGUAGE plpgsql;
