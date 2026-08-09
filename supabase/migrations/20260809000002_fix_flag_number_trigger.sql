-- 修复旗子编号分配触发器
-- 问题：FOR UPDATE 不能与聚合函数（MAX）一起使用
-- 解决方案：使用 ORDER BY + LIMIT 替代 MAX，并在最后一行上加锁

-- 创建修复后的触发器函数
CREATE OR REPLACE FUNCTION assign_flag_number()
RETURNS TRIGGER AS $$
DECLARE
  max_number INTEGER;
BEGIN
  -- 如果客户端没有提供编号（NULL），则自动分配
  IF NEW.number IS NULL THEN
    -- 使用 ORDER BY + LIMIT 获取最大编号，并加行锁
    -- 这样可以避免 "FOR UPDATE is not allowed with aggregate functions" 错误
    SELECT number INTO max_number
    FROM flags
    WHERE photo_id = NEW.photo_id
    ORDER BY number DESC
    LIMIT 1
    FOR UPDATE;

    -- 如果没有找到记录（第一个旗子），从 1 开始
    NEW.number := COALESCE(max_number, 0) + 1;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器本身不需要重建（函数已被替换）
-- 但为了确保一致性，我们重新创建触发器
DROP TRIGGER IF EXISTS before_insert_flag_number ON flags;

CREATE TRIGGER before_insert_flag_number
  BEFORE INSERT ON flags
  FOR EACH ROW
  EXECUTE FUNCTION assign_flag_number();

-- 添加注释
COMMENT ON FUNCTION assign_flag_number() IS '自动为新旗子分配连续编号，使用 ORDER BY + LIMIT + FOR UPDATE 确保原子性（避免聚合函数冲突）';
