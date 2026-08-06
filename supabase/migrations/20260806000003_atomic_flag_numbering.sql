-- 原子性旗子编号分配
-- 解决多用户并发插旗子时的编号冲突问题
--
-- 问题：客户端分配编号存在竞态条件
--   用户A查询 MAX(number) = 5
--   用户B查询 MAX(number) = 5
--   用户A插入 number = 6
--   用户B插入 number = 6  ❌ 冲突
--
-- 解决方案：使用数据库触发器 + FOR UPDATE 行锁
--   触发器在 INSERT 前自动分配编号
--   FOR UPDATE 确保读取和写入是原子操作
--
-- 使用方法：
--   1. 在 Supabase SQL Editor 中执行本文件
--   2. 客户端插入时不再传递 number 字段（传 NULL 或省略）
--   3. 触发器会自动分配下一个可用编号

-- 创建触发器函数
CREATE OR REPLACE FUNCTION assign_flag_number()
RETURNS TRIGGER AS $$
BEGIN
  -- 如果客户端没有提供编号（NULL），则自动分配
  IF NEW.number IS NULL THEN
    -- 使用 FOR UPDATE 锁定相关行，防止并发冲突
    -- COALESCE 处理第一个旗子的情况（返回 0）
    NEW.number := COALESCE(
      (SELECT MAX(number) FROM flags WHERE photo_id = NEW.photo_id FOR UPDATE),
      0
    ) + 1;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器（如果已存在则先删除）
DROP TRIGGER IF EXISTS before_insert_flag_number ON flags;

CREATE TRIGGER before_insert_flag_number
  BEFORE INSERT ON flags
  FOR EACH ROW
  EXECUTE FUNCTION assign_flag_number();

-- 添加注释
COMMENT ON FUNCTION assign_flag_number() IS '自动为新旗子分配连续编号，使用 FOR UPDATE 确保原子性';
COMMENT ON TRIGGER before_insert_flag_number ON flags IS '在插入旗子前自动分配编号，避免并发冲突';
