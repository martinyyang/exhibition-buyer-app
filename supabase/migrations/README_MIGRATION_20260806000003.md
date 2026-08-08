# 数据库迁移指南：原子性旗子编号分配

## 迁移文件
`20260806000003_atomic_flag_numbering.sql`

## 为什么需要这个迁移

**问题**：多用户并发插旗子时，可能产生重复编号
- 用户A和B同时点击 → 都查询到最大编号5 → 都创建编号6 → 冲突

**解决方案**：数据库触发器 + `FOR UPDATE` 行锁，确保编号分配的原子性

## 如何执行迁移

### 方法1：Supabase Dashboard（推荐）

1. 打开 Supabase 项目: https://supabase.com/dashboard
2. 进入 **SQL Editor**
3. 复制 `supabase/migrations/20260806000003_atomic_flag_numbering.sql` 的完整内容
4. 粘贴到 SQL Editor 并点击 **Run**
5. 确认执行成功（应该显示"Success. No rows returned"）

### 方法2：Supabase CLI（如果使用本地开发）

```bash
# 确保已安装 Supabase CLI
supabase db push

# 或者单独应用此迁移
supabase db push --migration 20260806000003_atomic_flag_numbering.sql
```

## 验证迁移成功

在 Supabase SQL Editor 中运行：

```sql
-- 检查触发器是否存在
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'before_insert_flag_number';

-- 应该返回：
-- trigger_name: before_insert_flag_number
-- event_manipulation: INSERT
-- event_object_table: flags
```

## 影响范围

- ✅ **向下兼容**：现有数据不受影响
- ✅ **客户端无感**：客户端代码已同步更新，无需额外操作
- ✅ **零停机**：迁移可在生产环境直接执行

## 测试并发插旗子

迁移完成后，打开两个浏览器窗口同时插旗子，验证编号不会重复。

## 回滚（如果需要）

如果需要回滚此迁移：

```sql
-- 删除触发器
DROP TRIGGER IF EXISTS before_insert_flag_number ON flags;

-- 删除函数
DROP FUNCTION IF EXISTS assign_flag_number();
```

**注意**：回滚后需要将客户端代码也回滚到之前的版本。

## 相关提交

- feat(flag): implement optimistic UI and atomic numbering (8944893)
- style: format code with dart format (389d668)
