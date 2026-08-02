# 中国网络环境优化说明

## 已实施的优化措施

### 1. 网络超时配置 (NetworkConfig)
针对中国网络环境的延迟特点，设置了合理的超时时间：
- **短超时 (10秒)**: 数据查询操作
- **中超时 (20秒)**: 图片上传操作  
- **长超时 (30秒)**: 大文件上传操作

### 2. 自动图片压缩
为减少上传数据量和时间：
- 自动检测图片大小，超过 1MB 自动压缩
- 压缩质量: 85%（保证清晰度）
- 最大尺寸: 1920x1920 像素
- 移动端和 Web 端分别处理

### 3. 实时连接优化
- 添加心跳检测机制，每 30 秒检查一次连接状态
- 自动监控 WebSocket 连接健康状况
- 防止连接僵死

### 4. 网络状态监控
提供了两个新组件：

**NetworkStatusService**
- 每 5 秒自动检测网络延迟
- 提供连接质量评级（良好/一般/较慢/很慢）
- 自动计算延迟时间

**NetworkStatusIndicator 组件**
```dart
// 在需要的地方添加网络状态指示器
NetworkStatusIndicator()

// 包裹整个页面显示横幅提示
NetworkStatusBanner(
  child: YourPageContent(),
)
```

### 5. 所有服务超时保护
为以下服务的所有网络操作添加了超时保护：
- PhotoService（照片上传、查询）
- FlagService（旗子创建、更新）
- BoothService（摊位管理）
- EventService（场次管理）

## 使用建议

### 如何在页面中添加网络状态提示

在 AppBar 中显示状态指示器：
```dart
AppBar(
  title: Text('页面标题'),
  actions: [
    NetworkStatusIndicator(),
    // 其他操作按钮
  ],
)
```

在整个应用层添加横幅提示：
```dart
// 在 main.dart 的 MaterialApp.router 中包裹
builder: (context, child) {
  return NetworkStatusBanner(child: child ?? SizedBox.shrink());
}
```

### 进一步优化建议

1. **考虑使用 CDN**：如果图片加载慢，可以考虑接入国内 CDN
2. **Supabase 区域**：当前使用国际版，如有条件可迁移到亚太区域
3. **离线缓存**：考虑添加本地缓存机制，减少网络请求
4. **数据预加载**：在网络良好时预加载常用数据

## 性能对比

优化前：
- 大图片上传：5-10MB 原始文件
- 无超时保护，可能无限等待
- 无网络状态反馈

优化后：
- 图片自动压缩至 1-2MB
- 10-30秒超时保护，及时反馈
- 实时网络状态监控
- 心跳保持连接活跃

## 配置文件

所有网络相关配置集中在：
`lib/core/config/network_config.dart`

可根据实际情况调整超时时间和压缩参数。
