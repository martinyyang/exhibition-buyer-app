# 部署指南 - 从代码到上线

## 快速开始（5步上线）

### 第1步：配置Supabase（15分钟）

#### 1.1 创建项目
1. 访问 https://supabase.com
2. 点击"New Project"
3. 填写项目信息：
   - Name: `exhibition-buyer-app`
   - Database Password: 保存好（后面需要）
   - Region: 选择最近的区域（如Singapore）
4. 等待项目初始化完成（约2分钟）

#### 1.2 执行数据库迁移
1. 进入项目 → SQL Editor
2. 复制 `supabase/migrations/20260722000000_initial_schema.sql` 的内容
3. 粘贴到SQL编辑器并执行
4. 验证成功：Table Editor中应该看到8张表

#### 1.3 配置Storage
1. 进入 Storage → Create bucket
2. 创建两个存储桶：
   - `photos` (Public, 2MB limit)
   - `suppliers` (Public, 2MB limit)

#### 1.4 获取API密钥
1. 进入 Settings → API
2. 复制以下值：
   - Project URL (如 `https://xxx.supabase.co`)
   - anon public key (以 `eyJhbG...` 开头)

---

### 第2步：配置应用（5分钟）

#### 2.1 创建环境变量文件
```bash
cd E:\gemini_projects\展会专用APP
copy .env.example .env
```

#### 2.2 编辑 .env 文件
```env
SUPABASE_URL=https://你的项目ID.supabase.co
SUPABASE_ANON_KEY=你的anon-key
```

#### 2.3 安装依赖
```bash
flutter pub get
```

---

### 第3步：运行测试（10分钟）

#### 3.1 生成Mock文件
```bash
dart run build_runner build --delete-conflicting-outputs
```

#### 3.2 运行单元测试
```bash
flutter test
```

预期输出：
```
All tests passed!
```

#### 3.3 运行集成测试（可选）
```bash
flutter test integration_test/app_test.dart
```

---

### 第4步：创建测试账号（5分钟）

在Supabase Dashboard中手动插入测试数据：

```sql
-- 1. 创建小组
INSERT INTO teams (id, name) VALUES 
('11111111-1111-1111-1111-111111111111', '测试小组');

-- 2. 创建用户（Supabase Auth）
-- 进入 Authentication → Add User
-- Email: buyer@test.com, Password: test123456
-- 获取生成的user_id，然后执行：

INSERT INTO users (id, email, role, team_id) VALUES 
('你的user_id', 'buyer@test.com', 'buyer', '11111111-1111-1111-1111-111111111111');

-- 同样方式创建远程用户
-- Email: remote@test.com, Password: test123456
INSERT INTO users (id, email, role, team_id) VALUES 
('你的remote_user_id', 'remote@test.com', 'remote', '11111111-1111-1111-1111-111111111111');
```

---

### 第5步：运行应用（2分钟）

#### 5.1 启动开发服务器

**移动端（Android/iOS）**
```bash
# 连接设备
flutter devices

# 运行
flutter run
```

**Web端**
```bash
flutter run -d chrome
```

#### 5.2 首次登录测试
1. 使用 `buyer@test.com` / `test123456` 登录
2. 验证颜色标识显示
3. 创建测试场次和摊位
4. 拍照测试

---

## 生产环境部署

### Android APK打包

```bash
# 1. 配置签名
# 编辑 android/app/build.gradle
# 添加签名配置（参考Flutter文档）

# 2. 构建Release APK
flutter build apk --release

# 3. 输出位置
# build/app/outputs/flutter-apk/app-release.apk

# 4. 分发
# 方式1：通过邮件/文件传输发给用户
# 方式2：上传到内部服务器
# 方式3：发布到Google Play（需要开发者账号）
```

### iOS IPA打包

```bash
# 1. 在Mac上配置证书
# 参考Flutter官方文档配置Apple Developer证书

# 2. 构建
flutter build ios --release

# 3. 通过Xcode Archive导出IPA

# 4. 分发
# 方式1：TestFlight内测
# 方式2：Ad Hoc分发
# 方式3：App Store发布
```

### Web部署

#### 方案1：GitHub Pages（免费）
```bash
# 1. 构建Web版本
flutter build web --release

# 2. 部署到GitHub Pages
# 将 build/web 目录内容推送到 gh-pages 分支
git subtree push --prefix build/web origin gh-pages

# 3. 访问
# https://你的用户名.github.io/仓库名
```

#### 方案2：Vercel（免费）
```bash
# 1. 安装Vercel CLI
npm install -g vercel

# 2. 构建
flutter build web --release

# 3. 部署
cd build/web
vercel --prod

# 4. 获得部署URL
```

#### 方案3：Supabase Storage（利用现有资源）
```bash
# 1. 构建
flutter build web --release

# 2. 上传到Supabase Storage
# 创建public bucket: web-app
# 上传 build/web/* 所有文件

# 3. 配置静态网站托管
# 在Supabase Dashboard中启用
```

---

## 生产环境配置检查清单

### Supabase配置
- [ ] 生产数据库已创建
- [ ] RLS策略已启用并测试
- [ ] Storage存储桶容量足够（监控使用量）
- [ ] Realtime已启用
- [ ] API密钥已保护（不提交到Git）
- [ ] 数据库备份已配置

### 应用配置
- [ ] .env文件配置正确（生产环境URL）
- [ ] 调试日志已关闭
- [ ] 版本号已更新（pubspec.yaml）
- [ ] 应用图标已替换
- [ ] 启动页已定制

### 安全检查
- [ ] .env文件在.gitignore中
- [ ] API密钥不在代码中硬编码
- [ ] HTTPS强制启用
- [ ] 敏感日志已移除
- [ ] RLS策略已验证

### 性能优化
- [ ] 照片压缩已启用（<2MB）
- [ ] 缓存策略已配置
- [ ] Realtime订阅已正确dispose
- [ ] 大列表使用ListView.builder
- [ ] 图片使用cached_network_image

---

## 用户培训指南

### 买手端培训（30分钟）

#### 1. 首次登录
- 打开App
- 输入账号密码
- 查看自己的颜色标识（记住颜色，便于远程识别）

#### 2. 创建场次
- 点击"新建场次"
- 输入展会名称（如"2026春季广交会"）
- 选择开始日期
- 保存

#### 3. 创建摊位
- 进入场次
- 点击"新建摊位"
- 输入摊位号（如B01）
- 保存

#### 4. 拍照上传
- 进入摊位
- 点击相机按钮
- 拍摄商品照片
- 可选：长按照片添加供应商信息

#### 5. 填写报价
- 点击照片进入详情页
- 查看远程团队插的旗子
- 在Flag表格中找到对应编号
- 填写卖家报价（人民币）
- 查看自动换算的价格

#### 6. 处理警告
- 看到🚨红色警告时，说明远程要求谈判
- 与卖家协商价格
- 更新报价后警告自动消失

### 远程端培训（30分钟）

#### 1. 登录和查看买手
- 登录远程账号（无颜色标识）
- 查看买手列表（显示颜色和在线状态）
- 识别哪些买手在线

#### 2. 设置汇率公式
- 进入设置
- 输入公式（如 `RMB * 0.14`）
- 查看预览计算结果
- 保存（当天全部照片使用此公式）

#### 3. 查看照片
- 按买手颜色筛选
- 浏览照片
- 点击照片进入详情

#### 4. 插旗标注
- 在照片上点击商品位置
- 系统自动生成编号（1, 2, 3...）
- 旗子显示在照片上
- Flag表格自动生成对应行

#### 5. 查看报价
- 等待买手填写报价
- 查看人民币价格
- 查看自动换算价格
- 对比网络价格决策

#### 6. 设置目标价
- 在Flag表格中输入目标价
- 买手端自动显示🚨警告
- 等待买手谈判和更新

---

## 监控和维护

### 日常监控

#### Supabase监控
1. 进入Supabase Dashboard
2. 查看 Logs（错误日志）
3. 查看 Database → Usage（存储和请求量）
4. 查看 Storage → Usage（照片存储量）

#### 关键指标
- 照片存储使用量（<1GB）
- 数据库存储（<500MB）
- API请求量（监控是否异常）
- Realtime连接数（<200）

### 数据清理

#### 展会结束后清理
```sql
-- 1. 导出重要数据（可选）
SELECT * FROM events WHERE name = '2026春季广交会';

-- 2. 删除旧照片（释放Storage空间）
-- 先从Storage删除文件，再删除数据库记录
DELETE FROM flags WHERE photo_id IN (
  SELECT id FROM photos WHERE booth_id IN (
    SELECT id FROM booths WHERE event_id = '旧场次ID'
  )
);
DELETE FROM photos WHERE booth_id IN (
  SELECT id FROM booths WHERE event_id = '旧场次ID'
);

-- 3. 保留场次和摊位记录（历史数据）
-- 或者删除：
DELETE FROM booths WHERE event_id = '旧场次ID';
DELETE FROM events WHERE id = '旧场次ID';
```

### 备份策略

#### Supabase自动备份
- Supabase免费版每天自动备份
- 保留7天
- 可在Dashboard中恢复

#### 手动导出（重要数据）
```bash
# 使用pg_dump导出数据库
pg_dump -h db.xxx.supabase.co -U postgres -d postgres > backup.sql
```

### 故障排查

#### 常见问题

**问题1：登录失败**
- 检查.env文件配置是否正确
- 检查Supabase项目是否正常运行
- 检查用户是否已在users表中创建

**问题2：照片上传失败**
- 检查Storage存储桶是否创建
- 检查存储空间是否已满（>1GB）
- 检查照片是否超过2MB（应该自动压缩）

**问题3：实时同步不工作**
- 检查Supabase Realtime是否启用
- 检查网络连接
- 重启应用

**问题4：警告标记不显示**
- 检查数据库触发器是否正确创建
- 查看flags表的needs_attention字段
- 检查时间戳字段是否正确

---

## 扩容计划（如需要）

### Supabase升级

如果免费额度不够，可升级到Pro版（$25/月）：
- 数据库：8GB
- 存储：100GB
- 带宽：250GB/月
- 实时连接：500

### 性能优化方案

#### 照片存储优化
1. 定期清理旧照片
2. 使用CDN加速（Supabase自带）
3. 压缩质量降低（从85%降到70%）

#### 数据库优化
1. 添加索引（已在迁移脚本中配置）
2. 定期VACUUM清理
3. 监控慢查询

---

## 应急预案

### 服务中断
1. 检查Supabase状态页：https://status.supabase.com
2. 如果Supabase宕机，等待恢复（通常<30分钟）
3. 应急方案：暂时使用线下Excel记录

### 数据丢失
1. 从Supabase自动备份恢复（最多丢失24小时数据）
2. 联系Supabase支持

### 大规模使用（超出预期）
1. 立即升级Supabase到Pro版
2. 优化照片压缩质量
3. 限制历史数据查询范围

---

## 支持和联系

### 技术文档
- Flutter官方文档：https://flutter.dev/docs
- Supabase文档：https://supabase.com/docs
- Riverpod文档：https://riverpod.dev

### 问题反馈
- GitHub Issues：创建issue描述问题
- 项目文档：查阅各个SUMMARY.md

---

**部署清单完成状态**

- ✅ Supabase配置指南
- ✅ 应用配置说明
- ✅ 测试验证流程
- ✅ 打包部署步骤
- ✅ 用户培训材料
- ✅ 监控维护方案
- ✅ 故障排查指南
- ✅ 扩容预案

**准备就绪，可以上线！**
