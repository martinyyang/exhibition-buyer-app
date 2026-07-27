# 🚨 RLS 策略修复 - 立即执行

## 问题
Web 应用显示错误：`infinite recursion detected in policy for relation "users"`

## 解决方案
在 Supabase SQL Editor 中执行以下 SQL：

```sql
DROP POLICY IF EXISTS "Team members can view team members" ON users;

CREATE POLICY "Users can view own data"
  ON users FOR SELECT
  TO authenticated
  USING (id = auth.uid());
```

## 执行步骤

### 方法 1：浏览器手动执行（最可靠）
1. 打开：https://supabase.com/dashboard/project/ppwjblvnixqeympfcqgs/sql/new
2. 登录（如果需要）
3. 粘贴上面的 SQL
4. 点击 **RUN** 按钮
5. 刷新应用测试：https://martinyyang.github.io/exhibition-buyer-app/

### 方法 2：使用 Supabase CLI（如果已安装）
```bash
supabase db execute --project-ref ppwjblvnixqeympfcqgs --file fix_rls_now.sql
```

## 验证
执行后，访问应用不应再显示无限递归错误。

---
生成时间：2026-07-27
