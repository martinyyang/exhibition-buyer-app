# 🚨 生产环境修复 - 立即执行

## 问题确认

刚刚运行 `test_complete_simulation.js` 确认：
- ✅ 登录成功
- ✅ 团队创建成功  
- ❌ **加入团队失败（team_id 更新返回 200 但实际未更新）**

这证明生产数据库的 RLS 策略冲突仍然存在。

## 立即修复步骤

### 1. 打开 Supabase SQL Editor

访问：https://supabase.com/dashboard/project/ppwjblvnixqeympfcqgs/sql/new

### 2. 执行以下 SQL（复制粘贴）

```sql
-- 删除所有可能存在的冲突 UPDATE 策略
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Users can update own data (not team_id)" ON users;

-- 创建唯一的 UPDATE 策略
CREATE POLICY "Users can update own data"
  ON users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 验证策略已创建
SELECT schemaname, tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename = 'users' AND cmd = 'UPDATE';
```

### 3. 验证修复

执行 SQL 后，应该看到查询结果：

| schemaname | tablename | policyname | cmd |
|------------|-----------|------------|-----|
| public | users | Users can update own data | UPDATE |

**只有一条记录**，说明策略冲突已解决。

### 4. 测试应用

在浏览器访问：https://exhibition-buyer-app.pages.dev/

1. 使用 `1@123.com` / `123456` 登录
2. 创建新团队或加入现有团队
3. 应该自动跳转到 `/events` 页面

如果还是失败，在命令行运行：
```bash
node test_complete_simulation.js
```

应该看到：
```
✅ 成功加入团队!
✅ 现在可以进入应用主界面 (/events)
```

## 为什么必须手动执行？

- 生产数据库已经存在冲突的策略（策略名称不匹配）
- 迁移文件只会在新环境部署时自动运行
- 已有的生产环境需要手动清理旧策略

## 预计时间

< 2 分钟
