# 摊位封面图片功能问题诊断报告

## 问题描述
用户反馈：为摊位 0925 上传封面图片后，图片不显示，卡片仍显示默认的灰色商店图标。

## 根本原因
**数据库迁移未应用到生产环境**

- 迁移文件 `supabase/migrations/20260808000001_add_booth_cover_image.sql` 已存在于代码库（commit f1f02fd）
- 但该 SQL 从未在生产数据库执行
- 当前生产环境的 `booths` 表**没有 `cover_image_url` 列**
- 测试查询返回错误："column booths.cover_image_url does not exist"

## 验证步骤

执行以下 Node.js 查询验证：
```bash
node -e "const { createClient } = require('@supabase/supabase-js'); \
const supabase = createClient('https://ppwjblvnixqeympfcqgs.supabase.co', 'ANON_KEY'); \
(async()=>{const {data,error}=await supabase.from('booths').select('cover_image_url').limit(1); \
console.log(error ? 'ERROR: ' + error.message : 'OK: ' + JSON.stringify(data))})();"
```

**结果**：`Error: column booths.cover_image_url does not exist`

## 影响范围
1. **照片上传到 Storage 成功** - 图片文件正常保存到 Supabase Storage
2. **数据库更新失败** - `updateBooth()` 调用抛出 400 错误，因为列不存在
3. **UI 显示默认图标** - `booth.coverImageUrl` 始终为 null，显示灰色商店图标

## 修复方案

### 立即修复（手动执行 SQL）

**必须通过 Supabase Dashboard SQL Editor 手动执行迁移**

1. 访问：https://supabase.com/dashboard/project/ppwjblvnixqeympfcqgs
2. 进入：SQL Editor
3. 执行以下 SQL：

```sql
ALTER TABLE booths ADD COLUMN IF NOT EXISTS cover_image_url TEXT;

COMMENT ON COLUMN booths.cover_image_url IS '摊位封面图片URL（可选）';
```

4. 验证列已添加：

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'booths'
ORDER BY ordinal_position;
```

### 验证修复

执行后，再次查询应该成功返回数据：
```bash
# 查询摊位 0925
node -e "const { createClient } = require('@supabase/supabase-js'); \
const supabase = createClient('https://ppwjblvnixqeympfcqgs.supabase.co', 'ANON_KEY'); \
(async()=>{const {data,error}=await supabase.from('booths') \
.select('booth_number, cover_image_url').eq('booth_number', '0925').limit(1); \
console.log(JSON.stringify(data||error, null, 2))})();"
```

### 后续改进

1. **自动化迁移流程**：
   - 考虑使用 Supabase CLI 管理迁移
   - 或在 CI/CD 中添加迁移检查步骤

2. **迁移追踪表**：
   - 创建 `schema_migrations` 表记录已应用的迁移
   - 防止手动执行时遗漏迁移

## 时间线

- **2026-08-08 15:07** - commit f1f02fd 添加封面图片功能和迁移文件
- **2026-08-08 15:xx** - 代码推送到 GitHub，Cloudflare Pages 自动部署
- **迁移步骤被遗漏** - SQL 未在生产数据库执行
- **2026-08-08 今天** - 用户报告问题，诊断发现根本原因

## 之前的错误分析

1. **PATCH 400 错误分析**（commit 322537c）：
   - 我认为是 `.update().eq().select().single()` 链式调用导致的
   - 实际上是因为 `cover_image_url` 列不存在，任何更新该字段的请求都会失败
   - 该修复无效，因为问题不在代码而在数据库 schema

2. **RLS 策略猜测**：
   - 我猜测是 Row Level Security 阻止访问
   - 用户正确指出：如果 RLS 有问题，整个摊位都无法加载，不只是封面图片

## 结论

这是一个**部署流程问题**，不是代码问题。代码和迁移文件都正确，但迁移 SQL 从未在生产环境执行。

修复非常简单：在 Supabase Dashboard 手动执行 2 行 SQL 即可立即解决问题。

---

**创建时间**：2026-08-08
**诊断工具**：Node.js + @supabase/supabase-js
**相关文件**：`APPLY_COVER_IMAGE_MIGRATION.sql`（已创建，包含完整执行步骤）
