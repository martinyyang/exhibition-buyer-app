# 数据库配置说明

## 🎯 目标

把所有需要手动操作的 Supabase SQL 配置集中到一个文件，**执行一次后再也不用手动操作**。

## 📁 文件说明

### 核心配置文件

- **`COMPLETE_SETUP.sql`** ⭐ - **一劳永逸配置文件**
  - 启用所有表的 Realtime 实时同步
  - 补充缺失的 DELETE 策略
  - 优化 RLS 策略避免递归查询
  - 添加实用函数和视图
  - **执行后不再需要手动配置数据库**

### 历史遗留文件（已被 COMPLETE_SETUP.sql 取代）

- `SETUP_PHOTOS_QUICK.sql` - 照片功能快速配置（已包含在完整配置中）
- `REALTIME_FIX.sql` - Realtime 修复（已包含在完整配置中）

## 🚀 使用方法

### 首次配置或完整重置

1. 登录 [Supabase Dashboard](https://supabase.com)
2. 进入你的项目 → 点击左侧 **SQL Editor**
3. 点击 **New Query**
4. 复制 `COMPLETE_SETUP.sql` 的**全部内容**
5. 粘贴到编辑器并点击 **Run**
6. 等待执行完成（约5-10秒）
7. 查看底部输出，确认所有表都在 Realtime publication 中

### ✅ 配置后的效果

执行 `COMPLETE_SETUP.sql` 后：

- ✅ **照片上传后自动刷新** - photos 表已启用 Realtime
- ✅ **标记、评论实时同步** - flags、comments 表已启用 Realtime
- ✅ **汇率公式实时更新** - exchange_settings、formula_history 已启用 Realtime
- ✅ **完整的 CRUD 权限** - 所有表都有 SELECT/INSERT/UPDATE/DELETE 策略
- ✅ **优化的查询性能** - RLS 策略使用 JOIN 替代嵌套子查询
- ✅ **实用函数和视图** - 添加了统计函数和详情视图

## 🔧 Migrations 说明

`supabase/migrations/` 目录下的文件是**数据库表结构定义**，需要在项目初始化时执行：

- `20260722000000_initial_schema.sql` - 完整的表结构和基础 RLS 策略
- `20260724000000_fix_registration_policies.sql` - 注册相关策略修复
- `20260727000000_*.sql` - RLS 递归问题修复

但这些 migrations **不包含**：
- ❌ Realtime 配置（需要手动 `ALTER PUBLICATION`）
- ❌ 部分 DELETE 策略
- ❌ 优化后的查询策略

所以需要额外执行 `COMPLETE_SETUP.sql`。

## 🤔 为什么需要这个文件？

### Supabase 的痛点

Supabase 作为 BaaS（Backend as a Service）平台，虽然不用写后端代码，但有个问题：

**很多配置需要去 Web Dashboard 手动执行 SQL**

| 配置项 | 能否自动化 | 说明 |
|--------|----------|------|
| 表结构 | ✅ 可以 | 通过 migrations 自动化 |
| RLS 策略 | ✅ 可以 | 通过 migrations 自动化 |
| Realtime | ❌ 不行 | 必须手动 `ALTER PUBLICATION` |
| Storage Bucket | ❌ 不行 | 必须在 Dashboard 点击创建 |
| Storage 策略 | ⚠️ 部分 | 可以用 SQL 但容易出错 |

### 实际经历

在开发过程中，我们遇到了：

1. **照片上传成功但不显示** → 忘了启用 photos 表的 Realtime
2. **展位创建失败** → booths 表的 RLS 策略递归查询
3. **标记无法删除** → flags 表缺少 DELETE 策略
4. **评论查询慢** → comments 策略嵌套4层子查询

每次都要：
1. 发现问题
2. 写 SQL 修复
3. 登录 Supabase Dashboard
4. 手动执行 SQL
5. 测试验证

**平均每个新功能上线需要手动操作 1-2 次。**

### 解决方案

把所有已知的和未来可能遇到的配置问题，集中到 `COMPLETE_SETUP.sql`：

- ✅ 一次性启用所有表的 Realtime
- ✅ 补全所有缺失的策略
- ✅ 优化所有已知的性能问题
- ✅ 添加实用的函数和视图

**执行一次后，理论上不再需要手动操作数据库。**

## ⚠️ 注意事项

1. **执行顺序**
   - 先执行 `supabase/migrations/` 下的所有文件（创建表结构）
   - 再执行 `COMPLETE_SETUP.sql`（完整配置）

2. **幂等性**
   - `COMPLETE_SETUP.sql` 可以重复执行（使用了 `DROP POLICY IF EXISTS`）
   - 不会破坏现有数据

3. **生产环境**
   - 在生产环境执行前，建议先在测试项目验证
   - 确保备份重要数据

## 📚 相关文档

- [Supabase Realtime 文档](https://supabase.com/docs/guides/realtime)
- [RLS 策略最佳实践](https://supabase.com/docs/guides/auth/row-level-security)
- [Storage 配置指南](https://supabase.com/docs/guides/storage)
