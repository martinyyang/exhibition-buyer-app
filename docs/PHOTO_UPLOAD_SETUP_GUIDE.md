# 照片上传功能配置指南

## ⚠️ 重要：必须先执行 Supabase 配置

照片上传功能需要在 Supabase 中配置 Storage bucket 和 RLS 策略。

## 步骤 1: 配置 Storage Bucket

1. 打开 **Supabase Dashboard**: https://supabase.com/dashboard/project/ppwjblvnixqeympfcqgs/sql/new
2. 执行 `docs/SUPABASE_STORAGE_SETUP.sql` 中的 SQL
3. 验证 bucket 创建成功：访问 Storage 页面应该看到 `photos` bucket

## 步骤 2: 配置 Photos 表 RLS 策略

1. 在同一个 SQL Editor 中
2. 执行 `docs/SUPABASE_PHOTOS_TABLE_RLS.sql` 中的 SQL
3. 验证策略创建成功：应该看到 "Success. No rows returned"

## 步骤 3: 验证配置

执行以下 SQL 验证：

```sql
-- 验证 bucket 存在
SELECT * FROM storage.buckets WHERE id = 'photos';

-- 验证 storage policies
SELECT policyname FROM pg_policies 
WHERE tablename = 'objects' AND policyname LIKE '%photos%';

-- 验证 photos 表 RLS policies
SELECT policyname FROM pg_policies 
WHERE tablename = 'photos';
```

应该看到：
- ✅ photos bucket 存在且 public = true
- ✅ 3 个 storage policies（upload、view、delete）
- ✅ 4 个 photos 表 policies（insert、select、update、delete）

## 步骤 4: 测试照片上传

1. 刷新应用页面
2. 进入任意摊位
3. 点击右下角 + 按钮
4. 选择照片并上传
5. 应该能看到上传的照片显示在网格中

## 常见问题

### Q: 上传时报错 "new row violates row-level security policy"
**A**: 检查 `photos` 表的 RLS 策略是否正确创建，特别是 INSERT 策略中的 booth_id 验证

### Q: 上传成功但看不到照片
**A**: 
1. 检查 Storage bucket 的 public 属性是否为 true
2. 检查浏览器控制台是否有 CORS 错误
3. 验证 photos 表的 SELECT 策略

### Q: 无法删除照片
**A**: 检查 Storage 的 DELETE 策略和 photos 表的 DELETE 策略是否都配置正确

## 技术实现细节

- **压缩**: 所有照片自动压缩到 2MB 以内（95% 质量）
- **存储**: 使用 Supabase Storage 的 `photos` bucket
- **路径**: `{userId}/{timestamp}_{filename}`
- **实时同步**: 使用 Realtime 订阅自动更新列表
- **团队隔离**: 通过 event_id -> booth_id -> team_id 链确保数据隔离
