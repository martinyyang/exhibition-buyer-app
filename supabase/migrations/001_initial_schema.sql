-- 小组表（先创建，因为其他表会引用它）
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 用户表
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('buyer', 'remote')),
  team_id UUID REFERENCES teams(id),
  daily_color TEXT CHECK (daily_color IN ('green', 'blue', 'yellow', 'red', 'purple', 'orange')),
  color_assigned_date DATE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 场次表（展会活动）
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  team_id UUID REFERENCES teams(id),
  is_active BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 展位表（摊位号可以在不同场次重复）
CREATE TABLE booths (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booth_number TEXT NOT NULL,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  team_id UUID REFERENCES teams(id),
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(event_id, booth_number)
);

-- 照片表
CREATE TABLE photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booth_id UUID REFERENCES booths(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  supplier_name TEXT,
  supplier_logo_url TEXT,
  uploaded_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

-- 标注旗子表
CREATE TABLE flags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  photo_id UUID REFERENCES photos(id) ON DELETE CASCADE,
  number INT NOT NULL,
  position_x FLOAT NOT NULL CHECK (position_x >= 0 AND position_x <= 1),
  position_y FLOAT NOT NULL CHECK (position_y >= 0 AND position_y <= 1),
  price_rmb DECIMAL(10,2),
  price_converted DECIMAL(10,2),
  target_price DECIMAL(10,2),
  target_price_updated_at TIMESTAMP,
  buyer_price_updated_at TIMESTAMP,
  needs_attention BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

-- 汇率设置表
CREATE TABLE exchange_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES teams(id),
  formula TEXT NOT NULL,
  valid_date DATE NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 汇率公式历史存档表
CREATE TABLE formula_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES teams(id),
  formula TEXT NOT NULL,
  last_used_at TIMESTAMP DEFAULT NOW(),
  use_count INT DEFAULT 1
);

-- Row Level Security 策略
ALTER TABLE booths ENABLE ROW LEVEL SECURITY;
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- 买手只能看到自己小组的数据
CREATE POLICY "Team members can view booths"
  ON booths FOR SELECT
  USING (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Team members can view photos"
  ON photos FOR SELECT
  USING (
    booth_id IN (
      SELECT id FROM booths WHERE team_id IN (
        SELECT team_id FROM users WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "Team members can view flags"
  ON flags FOR SELECT
  USING (
    photo_id IN (
      SELECT id FROM photos WHERE booth_id IN (
        SELECT id FROM booths WHERE team_id IN (
          SELECT team_id FROM users WHERE id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "Team members can view events"
  ON events FOR SELECT
  USING (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

-- 创建索引以提高查询性能
CREATE INDEX idx_booths_event_id ON booths(event_id);
CREATE INDEX idx_booths_team_id ON booths(team_id);
CREATE INDEX idx_photos_booth_id ON photos(booth_id);
CREATE INDEX idx_flags_photo_id ON flags(photo_id);
CREATE INDEX idx_flags_needs_attention ON flags(needs_attention);
CREATE INDEX idx_users_team_id ON users(team_id);
CREATE INDEX idx_events_team_id ON events(team_id);
CREATE INDEX idx_events_is_active ON events(is_active);
