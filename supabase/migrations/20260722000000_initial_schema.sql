-- 展会二手奢侈品采购协作App数据库Schema
-- 创建时间: 2026-07-22

-- 启用UUID扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 小组表
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 用户表
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('buyer', 'remote')),
  team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
  daily_color TEXT CHECK (daily_color IN ('green', 'blue', 'yellow', 'red', 'purple', 'orange')),
  color_assigned_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 场次表（展会活动）
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 展位表（摊位号可以在不同场次重复）
CREATE TABLE booths (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booth_number TEXT NOT NULL,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(event_id, booth_number)
);

-- 照片表
CREATE TABLE photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booth_id UUID REFERENCES booths(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  supplier_name TEXT,
  supplier_logo_url TEXT,
  uploaded_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 标注旗子表
CREATE TABLE flags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  photo_id UUID REFERENCES photos(id) ON DELETE CASCADE,
  number INTEGER NOT NULL,
  position_x DOUBLE PRECISION NOT NULL CHECK (position_x >= 0 AND position_x <= 1),
  position_y DOUBLE PRECISION NOT NULL CHECK (position_y >= 0 AND position_y <= 1),
  price_rmb NUMERIC(10,2),
  price_converted NUMERIC(10,2),
  target_price NUMERIC(10,2),
  target_price_updated_at TIMESTAMP WITH TIME ZONE,
  buyer_price_updated_at TIMESTAMP WITH TIME ZONE,
  needs_attention BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 汇率设置表
CREATE TABLE exchange_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  formula TEXT NOT NULL,
  valid_date DATE NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 汇率公式历史存档表
CREATE TABLE formula_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  formula TEXT NOT NULL,
  last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  use_count INTEGER DEFAULT 1,
  UNIQUE(team_id, formula)
);

-- 评论/沟通记录表（可选）
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  flag_id UUID REFERENCES flags(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引以提高查询性能
CREATE INDEX idx_users_team_id ON users(team_id);
CREATE INDEX idx_events_team_id ON events(team_id);
CREATE INDEX idx_events_is_active ON events(is_active);
CREATE INDEX idx_booths_event_id ON booths(event_id);
CREATE INDEX idx_booths_team_id ON booths(team_id);
CREATE INDEX idx_photos_booth_id ON photos(booth_id);
CREATE INDEX idx_flags_photo_id ON flags(photo_id);
CREATE INDEX idx_flags_needs_attention ON flags(needs_attention);
CREATE INDEX idx_comments_flag_id ON comments(flag_id);
CREATE INDEX idx_formula_history_team_id ON formula_history(team_id);
CREATE INDEX idx_formula_history_last_used_at ON formula_history(last_used_at DESC);

-- Row Level Security (RLS) 策略

-- 启用RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE booths ENABLE ROW LEVEL SECURITY;
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE exchange_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE formula_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- 用户策略：只能查看自己的信息
CREATE POLICY "Users can view own data"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own data"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- 小组策略：成员可以查看小组信息
CREATE POLICY "Team members can view team"
  ON teams FOR SELECT
  USING (
    id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

-- 场次策略：小组成员可以查看和管理本组场次
CREATE POLICY "Team members can view events"
  ON events FOR SELECT
  USING (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Team members can insert events"
  ON events FOR INSERT
  WITH CHECK (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Team members can update events"
  ON events FOR UPDATE
  USING (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Team members can delete events"
  ON events FOR DELETE
  USING (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

-- 摊位策略：小组成员可以查看和管理本组摊位
CREATE POLICY "Team members can view booths"
  ON booths FOR SELECT
  USING (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Team members can insert booths"
  ON booths FOR INSERT
  WITH CHECK (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Team members can update booths"
  ON booths FOR UPDATE
  USING (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Team members can delete booths"
  ON booths FOR DELETE
  USING (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

-- 照片策略：小组成员可以查看和管理本组照片
CREATE POLICY "Team members can view photos"
  ON photos FOR SELECT
  USING (
    booth_id IN (
      SELECT id FROM booths WHERE team_id IN (
        SELECT team_id FROM users WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "Team members can insert photos"
  ON photos FOR INSERT
  WITH CHECK (
    booth_id IN (
      SELECT id FROM booths WHERE team_id IN (
        SELECT team_id FROM users WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "Team members can update photos"
  ON photos FOR UPDATE
  USING (
    booth_id IN (
      SELECT id FROM booths WHERE team_id IN (
        SELECT team_id FROM users WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "Team members can delete photos"
  ON photos FOR DELETE
  USING (
    booth_id IN (
      SELECT id FROM booths WHERE team_id IN (
        SELECT team_id FROM users WHERE id = auth.uid()
      )
    )
  );

-- 旗子策略：小组成员可以查看和管理本组旗子
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

CREATE POLICY "Team members can insert flags"
  ON flags FOR INSERT
  WITH CHECK (
    photo_id IN (
      SELECT id FROM photos WHERE booth_id IN (
        SELECT id FROM booths WHERE team_id IN (
          SELECT team_id FROM users WHERE id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "Team members can update flags"
  ON flags FOR UPDATE
  USING (
    photo_id IN (
      SELECT id FROM photos WHERE booth_id IN (
        SELECT id FROM booths WHERE team_id IN (
          SELECT team_id FROM users WHERE id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "Team members can delete flags"
  ON flags FOR DELETE
  USING (
    photo_id IN (
      SELECT id FROM photos WHERE booth_id IN (
        SELECT id FROM booths WHERE team_id IN (
          SELECT team_id FROM users WHERE id = auth.uid()
        )
      )
    )
  );

-- 汇率设置策略：小组成员可以查看和管理本组汇率设置
CREATE POLICY "Team members can view exchange settings"
  ON exchange_settings FOR SELECT
  USING (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Team members can insert exchange settings"
  ON exchange_settings FOR INSERT
  WITH CHECK (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Team members can update exchange settings"
  ON exchange_settings FOR UPDATE
  USING (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

-- 公式历史策略：小组成员可以查看和管理本组公式历史
CREATE POLICY "Team members can view formula history"
  ON formula_history FOR SELECT
  USING (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Team members can insert formula history"
  ON formula_history FOR INSERT
  WITH CHECK (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Team members can update formula history"
  ON formula_history FOR UPDATE
  USING (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );

-- 评论策略：小组成员可以查看和管理本组评论
CREATE POLICY "Team members can view comments"
  ON comments FOR SELECT
  USING (
    flag_id IN (
      SELECT id FROM flags WHERE photo_id IN (
        SELECT id FROM photos WHERE booth_id IN (
          SELECT id FROM booths WHERE team_id IN (
            SELECT team_id FROM users WHERE id = auth.uid()
          )
        )
      )
    )
  );

CREATE POLICY "Team members can insert comments"
  ON comments FOR INSERT
  WITH CHECK (
    flag_id IN (
      SELECT id FROM flags WHERE photo_id IN (
        SELECT id FROM photos WHERE booth_id IN (
          SELECT id FROM booths WHERE team_id IN (
            SELECT team_id FROM users WHERE id = auth.uid()
          )
        )
      )
    )
  );

-- 触发器：自动更新 needs_attention 字段
CREATE OR REPLACE FUNCTION update_needs_attention()
RETURNS TRIGGER AS $$
BEGIN
  -- 当远程提交目标价时，设置 needs_attention = true
  IF NEW.target_price IS NOT NULL AND NEW.target_price_updated_at IS NOT NULL THEN
    IF OLD.target_price IS NULL OR OLD.target_price != NEW.target_price THEN
      NEW.needs_attention := TRUE;
    END IF;
  END IF;

  -- 当买手更新报价时，清除 needs_attention
  IF NEW.price_rmb IS NOT NULL AND NEW.buyer_price_updated_at IS NOT NULL THEN
    IF OLD.price_rmb IS NULL OR OLD.price_rmb != NEW.price_rmb THEN
      IF NEW.target_price_updated_at IS NOT NULL AND
         (OLD.buyer_price_updated_at IS NULL OR NEW.buyer_price_updated_at > NEW.target_price_updated_at) THEN
        NEW.needs_attention := FALSE;
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_needs_attention
  BEFORE UPDATE ON flags
  FOR EACH ROW
  EXECUTE FUNCTION update_needs_attention();

-- 函数：获取最近使用的公式
CREATE OR REPLACE FUNCTION get_recent_formulas(p_team_id UUID, p_limit INTEGER DEFAULT 5)
RETURNS TABLE (
  formula TEXT,
  last_used_at TIMESTAMP WITH TIME ZONE,
  use_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    fh.formula,
    fh.last_used_at,
    fh.use_count
  FROM formula_history fh
  WHERE fh.team_id = p_team_id
  ORDER BY fh.last_used_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 函数：增加公式使用次数
CREATE OR REPLACE FUNCTION increment_formula_usage(p_team_id UUID, p_formula TEXT)
RETURNS VOID AS $$
BEGIN
  INSERT INTO formula_history (team_id, formula, last_used_at, use_count)
  VALUES (p_team_id, p_formula, NOW(), 1)
  ON CONFLICT (team_id, formula)
  DO UPDATE SET
    last_used_at = NOW(),
    use_count = formula_history.use_count + 1;
END;
$$ LANGUAGE plpgsql;

-- 插入测试数据（可选，用于开发测试）
-- 注意：生产环境应该删除这部分或使用单独的seed文件

-- 创建测试小组
INSERT INTO teams (name) VALUES ('测试小组A');

-- 注意：用户数据需要通过 Supabase Auth 创建，这里只是示例结构
-- 实际使用时，用户会通过应用注册流程自动创建
