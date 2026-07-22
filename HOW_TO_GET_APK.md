# 📱 如何获取和安装APK

## 目前状况

由于本地环境**没有安装Android SDK**，无法直接构建APK。但不用担心，有以下几种方式可以获取APK：

---

## 🎯 方法1：使用在线构建服务（推荐）

### 使用GitHub Actions自动构建

这个项目上传到GitHub后，可以配置GitHub Actions自动构建APK。

**步骤：**

1. 代码已经准备好上传到GitHub
2. 配置GitHub Actions工作流（已包含在项目中）
3. 每次推送代码，Actions会自动构建APK
4. 在仓库的 **Releases** 页面下载APK

**优点：**
- ✅ 无需本地安装Android Studio
- ✅ 自动化构建，省时省力
- ✅ 每次更新都有新版本记录

---

## 🎯 方法2：使用Codemagic（免费）

**Codemagic** 是一个专门为Flutter设计的CI/CD平台，免费账户每月有500分钟构建时间。

**步骤：**

1. 访问 https://codemagic.io/
2. 用GitHub账号登录
3. 连接你的GitHub仓库
4. 点击 "Start new build"
5. 等待5-10分钟，下载APK

**优点：**
- ✅ 专为Flutter优化
- ✅ 免费额度充足
- ✅ 构建速度快

---

## 🎯 方法3：本地安装Android Studio构建

如果你想在本地构建APK，需要完整的Android开发环境。

### 步骤1：安装Android Studio

1. 下载 Android Studio：https://developer.android.com/studio
2. 安装时选择 "Standard" 安装
3. 等待SDK下载完成（约3-5GB）

### 步骤2：配置环境变量

**Windows系统：**

1. 右键"此电脑" → "属性" → "高级系统设置"
2. 点击"环境变量"
3. 添加以下系统变量：

```
变量名：ANDROID_HOME
变量值：C:\Users\你的用户名\AppData\Local\Android\Sdk
```

4. 在 Path 中添加：
```
%ANDROID_HOME%\platform-tools
%ANDROID_HOME%\tools
```

### 步骤3：接受Android许可协议

```bash
flutter doctor --android-licenses
```

按 `y` 接受所有许可协议。

### 步骤4：构建APK

```bash
cd E:\gemini_projects\exhibition-buyer-app
flutter build apk --release
```

生成的APK位置：
```
E:\gemini_projects\exhibition-buyer-app\build\app\outputs\flutter-apk\app-release.apk
```

**缺点：**
- ❌ 需要下载3-5GB的Android SDK
- ❌ 安装配置较复杂
- ❌ 占用大量磁盘空间

---

## 🎯 方法4：使用云端Flutter开发环境

### Flutter Cloud IDE（FlutLab）

**FlutLab** 是一个在线Flutter IDE，可以直接在浏览器中构建APK。

**步骤：**

1. 访问 https://flutlab.io/
2. 注册免费账号
3. 创建新项目并上传代码
4. 点击 "Build APK"
5. 下载构建好的APK

**优点：**
- ✅ 完全在线，无需本地环境
- ✅ 免费账户可用
- ✅ 简单快捷

---

## 📦 推荐方案

根据你的情况，我推荐：

### 🥇 首选：GitHub Actions

**原因：**
- 项目即将上传到GitHub
- 自动化构建，一劳永逸
- 版本管理清晰
- 完全免费

### 🥈 备选：Codemagic

**原因：**
- 专为Flutter设计
- 构建速度快
- 配置简单

### 🥉 最后：本地构建

**仅当：**
- 你经常需要修改代码并测试
- 你有足够的磁盘空间（20GB+）
- 你想学习Android开发

---

## 🚀 下一步

### 现在的状态

✅ **代码已准备好**
- Flutter项目已配置完成
- Supabase已连接
- 所有功能已实现

✅ **项目已英文化**
- 文件夹名：`exhibition-buyer-app`
- 包名：`com.exhibition.buyer_app`
- 所有配置文件已更新

⏳ **等待上传GitHub**
- 本地git仓库已初始化
- README已创建
- 等待推送到GitHub

---

## 📱 安装APK到手机

### Android手机安装步骤

1. **下载APK文件** 到手机
2. **允许安装未知来源应用**
   - 设置 → 安全 → 未知来源 → 允许
3. **点击APK文件** 开始安装
4. **打开应用** 注册登录

### 首次使用

1. 打开应用后，点击"注册"
2. 输入邮箱和密码
3. 选择角色（买手/领班）
4. 系统自动分配颜色标识
5. 开始使用！

---

## ⚠️ 注意事项

### APK签名

- 本地构建的APK是**未签名**的debug版本
- 仅供测试使用
- 正式发布需要配置签名密钥

### 权限要求

应用需要以下权限：
- 📷 **相机** - 拍摄照片
- 🖼️ **存储** - 访问相册
- 🌐 **网络** - 上传下载数据

---

## 🆘 遇到问题？

### APK无法安装

**问题**：提示"应用未安装"

**解决方案**：
- 检查手机Android版本（需要5.0+）
- 卸载旧版本后重新安装
- 清除下载缓存后重试

### 应用闪退

**问题**：打开应用立即闪退

**解决方案**：
- 检查`.env`文件配置是否正确
- 确认Supabase URL和Key有效
- 查看日志：`adb logcat`

---

## 📞 需要帮助？

如果以上方法都无法解决，请：

1. 在GitHub仓库提交Issue
2. 附上详细的错误信息
3. 我会尽快回复

---

<div align="center">

**🎉 祝你使用愉快！**

</div>
