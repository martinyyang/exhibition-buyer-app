# Exhibition Buyer App - 展会买手协同管理系统

<div align="center">

**专为展会现场买手团队设计的实时协作管理应用**

[![Flutter](https://img.shields.io/badge/Flutter-3.24.5-blue.svg)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-2.0-green.svg)](https://supabase.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[功能特性](#功能特性) • [快速开始](#快速开始) • [技术栈](#技术栈) • [部署指南](#部署指南)

</div>

---

## 📱 项目简介

这是一个专为**展会二手奢侈品采购团队**设计的实时协作管理应用。帮助现场买手与远程团队高效协同，实现：

- 📸 **现场拍照记录** - 快速拍摄并上传供应商商品照片
- 🏷️ **智能标注系统** - 在照片上标记商品信息和报价
- 🎨 **每日颜色标识** - 自动分配颜色，快速识别买手身份
- 💱 **自动汇率换算** - 支持自定义公式的实时价格换算
- 👥 **团队权限隔离** - 买手小组数据隔离，领班全局管理
- ⚡ **实时数据同步** - 基于Supabase Realtime的毫秒级同步
- 📴 **离线工作支持** - 本地缓存确保无网络环境下正常使用

---

## 🎯 功能特性

### 核心功能模块

#### 1️⃣ 用户认证与权限管理
- 邮箱注册/登录
- 角色权限系统（买手/领班/管理员）
- 每日自动分配颜色标识（8种颜色）
- 团队/小组权限隔离

#### 2️⃣ 场次管理
- 创建展会场次（名称、地点、时间）
- 场次状态管理（激活/归档）
- 自动切换当前活跃场次
- 场次历史记录查询

#### 3️⃣ 摊位管理
- 快速添加摊位（扫码/手动输入）
- 摊位信息编辑（位置、联系方式）
- 关联场次管理
- 摊位搜索与筛选

#### 4️⃣ 照片上传与管理
- 拍照或相册选择
- 自动压缩上传（节省流量）
- 照片元信息记录（拍摄者、时间、颜色）
- 云端存储（Supabase Storage）

#### 5️⃣ 旗子标注系统
- 在照片上点击添加旗子标记
- 记录商品信息（名称、描述）
- 录入价格和币种
- 标记警告状态（红旗警告）
- 旗子颜色与买手身份同步

#### 6️⃣ 报价与换算
- 自定义换算公式（支持四则运算）
- 公式历史存档
- 实时预览换算结果
- 批量换算功能

#### 7️⃣ 评论与协作
- 照片评论功能
- @提及团队成员
- 实时评论通知
- 评论历史记录

---

## 🚀 快速开始

### 前置要求

- Flutter SDK 3.24.5+
- Dart SDK 3.5.4+
- Android Studio / Xcode
- Supabase账号

### 安装步骤

```bash
# 1. 克隆仓库
git clone https://github.com/YOUR_USERNAME/exhibition-buyer-app.git
cd exhibition-buyer-app

# 2. 安装依赖
flutter pub get

# 3. 配置环境变量
cp .env.example .env
# 编辑 .env 文件，填入你的Supabase配置

# 4. 运行应用
flutter run
```

### 配置Supabase

详细的Supabase配置步骤请参考 [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

## 🛠️ 技术栈

### 前端框架
- **Flutter 3.24.5** - 跨平台UI框架
- **Dart 3.5.4** - 开发语言

### 状态管理
- **Riverpod 2.4.0** - 类型安全的状态管理

### 后端服务
- **Supabase** - 后端即服务
  - PostgreSQL 数据库
  - Realtime 实时订阅
  - Storage 文件存储
  - Auth 用户认证

### 核心库
- **go_router** - 声明式路由
- **image_picker** - 图片选择
- **flutter_image_compress** - 图片压缩
- **math_expressions** - 公式计算
- **cached_network_image** - 图片缓存

---

## 📦 项目结构

```
exhibition-buyer-app/
├── lib/
│   ├── core/                  # 核心功能
│   │   ├── models/           # 基础模型
│   │   ├── providers/        # 全局状态
│   │   └── utils/            # 工具类
│   ├── features/             # 功能模块
│   │   ├── auth/            # 认证模块
│   │   ├── event/           # 场次管理
│   │   ├── booth/           # 摊位管理
│   │   ├── photo/           # 照片管理
│   │   ├── flag/            # 旗子标注
│   │   ├── formula/         # 公式换算
│   │   └── comment/         # 评论系统
│   └── main.dart            # 应用入口
├── test/                     # 单元测试
├── integration_test/         # E2E测试
├── supabase/                # 数据库迁移脚本
└── docs/                    # 项目文档
```

---

## 🗄️ 数据库设计

### 核心表结构

- **teams** - 团队表
- **users** - 用户表（关联team）
- **events** - 场次表
- **booths** - 摊位表
- **photos** - 照片表
- **flags** - 旗子标注表
- **exchange_settings** - 换算配置表
- **formula_history** - 公式历史表
- **comments** - 评论表

详细的数据库设计请参考 [supabase/migrations](supabase/migrations)

---

## 🔐 权限设计

### 角色权限

| 功能 | 买手 | 领班 | 管理员 |
|------|------|------|--------|
| 查看本组数据 | ✅ | ✅ | ✅ |
| 查看所有数据 | ❌ | ✅ | ✅ |
| 创建场次 | ❌ | ✅ | ✅ |
| 删除数据 | ❌ | ✅ | ✅ |
| 管理用户 | ❌ | ❌ | ✅ |
| 设置权限 | ❌ | ❌ | ✅ |

---

## 📝 使用指南

### 1. 首次使用

1. 注册账号（邮箱 + 密码）
2. 选择角色（买手/领班）
3. 系统自动分配今日颜色标识

### 2. 创建场次（领班权限）

1. 点击"新建场次"
2. 输入展会名称、地点、开始/结束时间
3. 保存后自动设为当前活跃场次

### 3. 添加摊位

1. 进入某个场次
2. 点击"添加摊位"
3. 输入摊位号和位置信息

### 4. 拍照记录

1. 进入摊位详情
2. 点击"拍照"按钮
3. 拍摄照片或从相册选择
4. 自动上传到云端

### 5. 添加旗子标注

1. 点击照片上的目标位置
2. 输入商品名称、描述
3. 录入价格和币种
4. 旗子颜色自动匹配你的身份颜色

### 6. 设置换算公式

1. 进入"设置"页面
2. 输入换算公式（例如：`RMB * 0.14`）
3. 预览换算结果
4. 保存后自动应用到所有报价

---

## 🧪 测试

### 运行单元测试

```bash
flutter test
```

### 运行集成测试

```bash
flutter test integration_test/app_test.dart
```

详细的测试指南请参考 [E2E_TEST_GUIDE.md](E2E_TEST_GUIDE.md)

---

## 📱 安装APK

由于需要Android SDK才能构建APK，这里提供两种获取方式：

### 方法1：使用GitHub Actions自动构建
- 代码推送到GitHub后，Actions会自动构建APK
- 在Releases页面下载最新版本

### 方法2：本地构建（需要安装Android Studio）
```bash
flutter build apk --release
```
生成的APK位于：`build/app/outputs/flutter-apk/app-release.apk`

---

## 🚧 部署指南

详细的部署步骤请参考：
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - 完整部署指南
- [SUPABASE_SETUP.md](SUPABASE_SETUP.md) - Supabase配置说明

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 👥 贡献

欢迎提交 Issue 和 Pull Request！

---

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 [GitHub Issue](https://github.com/YOUR_USERNAME/exhibition-buyer-app/issues)
- 邮箱：your-email@example.com

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给个星标支持！**

Made with ❤️ by Exhibition Buyer Team

</div>
