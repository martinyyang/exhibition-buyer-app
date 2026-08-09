# 摊位供应商信息功能迁移说明

## 功能说明
为摊位添加供应商信息字段（supplier_name 和 supplier_logo_url），允许用户在摊位级别记录供应商信息。

## 数据库变更
添加两个可选字段到 `booths` 表：
- `supplier_name` (TEXT, nullable) - 供应商名称
- `supplier_logo_url` (TEXT, nullable) - 供应商Logo URL

## 执行步骤

### 方式一：通过 Supabase Dashboard（推荐）

1. 访问：https://supabase.com/dashboard/project/ppwjblvnixqeympfcqgs
2. 进入：SQL Editor
3. 执行以下 SQL：

```sql
ALTER TABLE booths
ADD COLUMN IF NOT EXISTS supplier_name TEXT,
ADD COLUMN IF NOT EXISTS supplier_logo_url TEXT;

COMMENT ON COLUMN booths.supplier_name IS '供应商名称（可选）';
COMMENT ON COLUMN booths.supplier_logo_url IS '供应商Logo URL（可选）';
```

### 方式二：使用 Node.js 脚本

```bash
node supabase/apply_migration.js
```

## 验证迁移

执行后，验证字段已添加：

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'booths'
AND column_name IN ('supplier_name', 'supplier_logo_url');
```

预期结果：
```
column_name        | data_type | is_nullable
-------------------+-----------+-------------
supplier_name      | text      | YES
supplier_logo_url  | text      | YES
```

## UI 功能

迁移后，用户可以：
1. 在摊位卡片菜单中选择"添加供应商信息"
2. 输入供应商名称
3. （可选）上传供应商Logo
4. 供应商名称显示在摊位卡片上

## 相关文件
- 迁移文件：`supabase/migrations/20260809000001_add_booth_supplier_info.sql`
- 模型更新：`lib/features/booth/models/booth.dart`
- UI 更新：`lib/features/booth/screens/booth_list_screen.dart`

---
创建时间：2026-08-09
