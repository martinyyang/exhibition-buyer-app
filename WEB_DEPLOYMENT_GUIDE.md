# 🌐 Web 版本部署指南

## 🎉 项目已改造为 Web 应用！

你不再需要下载和安装 APK，现在可以直接通过浏览器访问应用。

---

## 📱 访问地址

**生产地址**（推送到 master 分支后自动部署）：
```
https://martinyyang.github.io/exhibition-buyer-app/
```

**预计部署时间**：推送代码后 3-5 分钟

---

## ✅ 已完成的改造

### 1. 平台支持
- ✅ Web 平台初始化（`web/` 目录）
- ✅ 图片服务跨平台抽象（Mobile + Web）
- ✅ UI 层 Web 适配（文件上传 vs 相机）
- ✅ 响应式布局（桌面/平板/手机）

### 2. 核心功能
- ✅ **图片上传**：Web 使用文件选择器，Mobile 使用相机
- ✅ **图片压缩**：Web 内存处理，Mobile 文件系统
- ✅ **环境变量**：已有 fallback 机制支持 Web
- ✅ **实时同步**：Supabase Realtime 跨平台

### 3. 自动部署
- ✅ GitHub Actions CI/CD
- ✅ 自动构建 Web 版本
- ✅ 自动部署到 GitHub Pages

---

## 🚀 本地开发

### 运行 Web 开发服务器

```bash
# 方法 1：Chrome 调试
flutter run -d chrome

# 方法 2：Edge 调试
flutter run -d edge

# 方法 3：本地 HTTP 服务器
flutter build web --release
python -m http.server 8000 -d build/web
# 访问 http://localhost:8000
```

### 构建生产版本

```bash
flutter build web --release --base-href="/exhibition-buyer-app/"
```

**产物位置**：`build/web/`

---

## 📦 部署流程

### 自动部署（推荐）

```bash
# 1. 提交代码
git add .
git commit -m "Your changes"

# 2. 推送到 master
git push origin master

# 3. 等待 GitHub Actions 完成（3-5 分钟）
# 查看：https://github.com/martinyyang/exhibition-buyer-app/actions

# 4. 访问网站
# https://martinyyang.github.io/exhibition-buyer-app/
```

### 手动部署

```bash
# 1. 构建
flutter build web --release --base-href="/exhibition-buyer-app/"

# 2. 部署到 gh-pages 分支
cd build/web
git init
git add .
git commit -m "Deploy web app"
git branch -M gh-pages
git remote add origin https://github.com/martinyyang/exhibition-buyer-app.git
git push -f origin gh-pages
```

---

## 🔧 关键文件说明

### Web 平台文件
```
web/
├── index.html          # 主页面（包含 base href 占位符）
├── manifest.json       # PWA 配置
└── icons/             # 应用图标
```

### 图片服务（跨平台）
```
lib/features/photo/services/
├── image_helper_interface.dart   # 平台抽象接口
├── image_helper_mobile.dart      # 移动端实现
├── image_helper_web.dart         # Web 实现
└── image_helper_service.dart     # 工厂导出
```

### CI/CD 配置
```
.github/workflows/ci.yml
  └── build-web job
      ├── 构建：flutter build web --release
      └── 部署：peaceiris/actions-gh-pages@v3
```

---

## 📊 Web vs 移动端对比

| 功能 | 移动端 (Android) | Web 版本 |
|------|----------------|----------|
| **安装** | 需下载 APK (10-50MB) | 无需安装，直接访问 |
| **更新** | 需重新下载安装 | 自动更新，刷新即可 |
| **图片上传** | 相机 + 相册 | 文件选择器 |
| **离线支持** | ✅ 完整支持 | ⚠️ 需要网络 |
| **推送通知** | ✅ 原生支持 | ⚠️ Web Push (可选) |
| **性能** | ⚡ 原生性能 | 📦 接近原生 |
| **跨平台** | Android 设备 | 所有设备 + 浏览器 |

---

## 🎯 使用场景

### Web 版本适合

- ✅ 快速试用（无需安装）
- ✅ 电脑端使用（更大屏幕）
- ✅ 临时访问（展会期间）
- ✅ 多设备切换（手机/平板/电脑）
- ✅ 分享链接给团队

### 移动端适合

- ✅ 长期使用（更好的性能）
- ✅ 离线场景（展会网络不稳定）
- ✅ 推送提醒
- ✅ 更流畅的用户体验

---

## 🧪 测试清单

### 功能测试
- [ ] 注册/登录
- [ ] 创建/选择活动
- [ ] 上传图片（文件选择器）
- [ ] 查看图片列表
- [ ] 编辑图片标签
- [ ] 实时同步

### 响应式测试
- [ ] 桌面视图 (1200px+)
- [ ] 平板视图 (768px-1199px)
- [ ] 手机视图 (< 768px)

### 浏览器兼容性
- [ ] Chrome/Edge
- [ ] Firefox
- [ ] Safari (Mac/iOS)
- [ ] 移动端浏览器

---

## 🐛 常见问题

### Q1: 网站无法访问？

**检查 GitHub Pages 设置**：
1. 进入仓库 Settings → Pages
2. Source: `gh-pages` 分支
3. 等待部署完成（绿色勾号）

**检查 CI/CD**：
- 查看 Actions 是否成功：https://github.com/martinyyang/exhibition-buyer-app/actions
- 确保推送到 `master` 分支

### Q2: 图片上传失败？

**检查 Supabase 配置**：
- Storage 存储桶 `photos` 是否存在
- 存储桶权限是否正确（Public）
- RLS 策略是否允许上传

**检查浏览器控制台**：
- F12 打开开发者工具
- 查看 Network 和 Console 错误

### Q3: 样式显示不正常？

**清除浏览器缓存**：
- Ctrl + Shift + R（强制刷新）
- 或 F12 → Network → Disable cache

### Q4: 环境变量未加载？

Web 版本使用 **fallback 硬编码值**（`lib/main.dart:29-37`）：
```dart
supabaseUrl = 'https://ppwjblvnixqeympfcqgs.supabase.co';
supabaseKey = 'eyJhbGc...';
```

这是正常的，Supabase anon key 设计为可公开。

---

## 🔄 回滚到移动端

如果需要回到纯移动端：

```bash
# 删除 Web 平台文件
rm -rf web/

# 删除 Web 相关代码
git checkout HEAD~1 -- lib/features/photo/services/
git checkout HEAD~1 -- lib/features/photo/screens/photo_grid_screen.dart

# 恢复 CI 配置
git checkout HEAD~1 -- .github/workflows/ci.yml
```

---

## 📈 后续优化建议

### 短期（1-2周）
- [ ] PWA 支持（添加到主屏幕）
- [ ] 离线缓存（Service Worker）
- [ ] 自定义域名

### 中期（1个月）
- [ ] Web 端图片裁剪
- [ ] 拖拽上传
- [ ] 批量上传
- [ ] SEO 优化

### 长期（3个月）
- [ ] Web Push 通知
- [ ] IndexedDB 离线存储
- [ ] 性能监控

---

## 🎉 总结

✅ **不再需要下载 APK**  
✅ **访问链接即可使用**  
✅ **自动更新，无需重新安装**  
✅ **所有设备都能访问**  

**从"下载后才发现不能用"到"打开浏览器就能用"！** 🚀

---

**访问地址**：https://martinyyang.github.io/exhibition-buyer-app/

**推送代码后 3-5 分钟自动部署**
