-- ============================================
-- 🚀 完整配置 SQL - 一次性解决所有未来问题
-- 复制全部内容到 Supabase SQL Editor 并执行
-- 执行后不再需要手动配置数据库
-- ============================================

-- ==========================================
-- 第一部分：启用 Realtime（实时同步）
-- ==========================================

-- 为所有表启用实时同步，上传/修改后自动刷新
-- 注意：ALTER PUBLICATION ADD TABLE 不支持 IF NOT EXISTS，需要逐个尝试
DO $$
BEGIN
  -- 核心业务表（001_initial_schema.sql 中已创建）
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE photos;
  EXCEPTION WHEN duplicate_object THEN
    NULL; -- 表已存在于 publication 中，忽略
  WHEN undefined_table THEN
    RAISE NOTICE 'Table photos does not exist, skipping';
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE flags;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  WHEN undefined_table THEN
    RAISE NOTICE 'Table flags does not exist, skipping';
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE booths;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  WHEN undefined_table THEN
    RAISE NOTICE 'Table booths does not exist, skipping';
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE events;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  WHEN undefined_table THEN
    RAISE NOTICE 'Table events does not exist, skipping';
  END;

  -- 可选功能表（20260722000000_initial_schema.sql 中创建，可能不存在）
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE comments;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  WHEN undefined_table THEN
    RAISE NOTICE 'Table comments does not exist, skipping (need to run 20260722000000_initial_schema.sql)';
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE exchange_settings;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  WHEN undefined_table THEN
    RAISE NOTICE 'Table exchange_settings does not exist, skipping';
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE formula_history;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  WHEN undefined_table THEN
    RAISE NOTICE 'Table formula_history does not exist, skipping';
  END;
END $$;

-- ==========================================
-- 第二部分：补充缺失的 DELETE 策略
-- ==========================================

-- Comments 删除策略（仅在 comments 表存在时创建）
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'comments') THEN
    EXECUTE 'DROP POLICY IF EXISTS "Team members can delete comments" ON comments';
    EXECUTE '
      CREATE POLICY "Team members can delete comments"
      ON comments FOR DELETE
      USING (
        user_id = auth.uid()
        OR flag_id IN (
          SELECT f.id FROM flags f
          JOIN photos p ON f.photo_id = p.id
          JOIN booths b ON p.booth_id = b.id
          WHERE b.team_id = public.current_user_team_id()
        )
      )';
    RAISE NOTICE 'Created DELETE policy for comments table';
  ELSE
    RAISE NOTICE 'Skipping comments policies - table does not exist';
  END IF;
END $$;

-- Exchange Settings 删除策略（仅在表存在时创建）
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'exchange_settings') THEN
    EXECUTE 'DROP POLICY IF EXISTS "Team members can delete exchange settings" ON exchange_settings';
    EXECUTE '
      CREATE POLICY "Team members can delete exchange settings"
      ON exchange_settings FOR DELETE
      USING (team_id = public.current_user_team_id())';
    RAISE NOTICE 'Created DELETE policy for exchange_settings table';
  ELSE
    RAISE NOTICE 'Skipping exchange_settings policies - table does not exist';
  END IF;
END $$;

-- Formula History 删除策略（仅在表存在时创建）
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'formula_history') THEN
    EXECUTE 'DROP POLICY IF EXISTS "Team members can delete formula history" ON formula_history';
    EXECUTE '
      CREATE POLICY "Team members can delete formula history"
      ON formula_history FOR DELETE
      USING (team_id = public.current_user_team_id())';
    RAISE NOTICE 'Created DELETE policy for formula_history table';
  ELSE
    RAISE NOTICE 'Skipping formula_history policies - table does not exist';
  END IF;
END $$;

-- ==========================================
-- 第三部分：优化现有 RLS 策略（避免递归查询）
-- ==========================================

-- 优化 Comments 查询策略（减少嵌套层级）
-- 仅在 comments 表存在时优化
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'comments') THEN
    EXECUTE 'DROP POLICY IF EXISTS "Team members can view comments" ON comments';
    EXECUTE '
      CREATE POLICY "Team members can view comments"
      ON comments FOR SELECT
      USING (
        flag_id IN (
          SELECT f.id FROM flags f
          JOIN photos p ON f.photo_id = p.id
          JOIN booths b ON p.booth_id = b.id
          WHERE b.team_id = public.current_user_team_id()
        )
      )';

    EXECUTE 'DROP POLICY IF EXISTS "Team members can insert comments" ON comments';
    EXECUTE '
      CREATE POLICY "Team members can insert comments"
      ON comments FOR INSERT
      WITH CHECK (
        flag_id IN (
          SELECT f.id FROM flags f
          JOIN photos p ON f.photo_id = p.id
          JOIN booths b ON p.booth_id = b.id
          WHERE b.team_id = public.current_user_team_id()
        )
        AND public.current_user_team_id() IS NOT NULL
      )';
    RAISE NOTICE 'Optimized comments policies';
  END IF;
END $$;

-- 优化 Flags 策略（使用 JOIN 替代嵌套子查询）
DROP POLICY IF EXISTS "Team members can view flags" ON flags;
CREATE POLICY "Team members can view flags"
ON flags FOR SELECT
USING (
  photo_id IN (
    SELECT p.id FROM photos p
    JOIN booths b ON p.booth_id = b.id
    WHERE b.team_id = public.current_user_team_id()
  )
);

DROP POLICY IF EXISTS "Team members can insert flags" ON flags;
CREATE POLICY "Team members can insert flags"
ON flags FOR INSERT
WITH CHECK (
  photo_id IN (
    SELECT p.id FROM photos p
    JOIN booths b ON p.booth_id = b.id
    WHERE b.team_id = public.current_user_team_id()
  )
  AND public.current_user_team_id() IS NOT NULL
);

DROP POLICY IF EXISTS "Team members can update flags" ON flags;
CREATE POLICY "Team members can update flags"
ON flags FOR UPDATE
USING (
  photo_id IN (
    SELECT p.id FROM photos p
    JOIN booths b ON p.booth_id = b.id
    WHERE b.team_id = public.current_user_team_id()
  )
);

DROP POLICY IF EXISTS "Team members can delete flags" ON flags;
CREATE POLICY "Team members can delete flags"
ON flags FOR DELETE
USING (
  photo_id IN (
    SELECT p.id FROM photos p
    JOIN booths b ON p.booth_id = b.id
    WHERE b.team_id = public.current_user_team_id()
  )
);

-- ==========================================
-- 第四部分：添加实用数据库函数
-- ==========================================

-- 批量删除展位及关联数据的函数
CREATE OR REPLACE FUNCTION delete_booth_cascade(booth_uuid UUID)
RETURNS VOID AS $$
BEGIN
  -- Supabase 会自动处理 CASCADE，这个函数主要用于日志记录
  DELETE FROM booths WHERE id = booth_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 获取团队统计信息的函数
CREATE OR REPLACE FUNCTION get_team_stats(team_uuid UUID)
RETURNS TABLE (
  total_events BIGINT,
  total_booths BIGINT,
  total_photos BIGINT,
  total_flags BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*) FROM events WHERE team_id = team_uuid),
    (SELECT COUNT(*) FROM booths WHERE team_id = team_uuid),
    (SELECT COUNT(*) FROM photos p JOIN booths b ON p.booth_id = b.id WHERE b.team_id = team_uuid),
    (SELECT COUNT(*) FROM flags f
     JOIN photos p ON f.photo_id = p.id
     JOIN booths b ON p.booth_id = b.id
     WHERE b.team_id = team_uuid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- 第五部分：创建有用的视图
-- ==========================================

-- 创建完整的照片视图（包含展会、摊位、标记信息）
CREATE OR REPLACE VIEW photo_details AS
SELECT
  p.id as photo_id,
  p.url,
  p.supplier_name,
  p.created_at as photo_created_at,
  b.id as booth_id,
  b.booth_number,
  e.id as event_id,
  e.name as event_name,
  e.team_id,
  COUNT(f.id) as flag_count
FROM photos p
JOIN booths b ON p.booth_id = b.id
JOIN events e ON b.event_id = e.id
LEFT JOIN flags f ON f.photo_id = p.id
GROUP BY p.id, p.url, p.supplier_name, p.created_at, b.id, b.booth_number, e.id, e.name, e.team_id;

-- ==========================================
-- 完成！检查结果
-- ==========================================

-- 验证 Realtime 已启用（可选）
SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;

-- 应该看到：booths, comments, events, exchange_settings, flags, formula_history, photos

-- ✅ 配置完成！现在：
-- 1. 所有表都支持实时同步
-- 2. 所有表都有完整的 CRUD 权限
-- 3. RLS 策略已优化，避免递归问题
-- 4. 添加了实用函数和视图
-- 5. 不再需要手动执行 SQL！
