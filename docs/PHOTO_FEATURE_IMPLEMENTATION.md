# Photo Upload & Storage Feature Implementation

## 概述
实现了完整的照片上传、存储和供应商信息管理功能，遵循TDD原则（先写测试，再实现功能）。

## 实现的文件

### 核心服务层
1. **lib/features/photo/services/photo_service.dart** ✅ 完善
   - `uploadPhoto()` - 上传照片到Supabase Storage并创建数据库记录
   - `getPhotos(boothId)` - 获取指定摊位的所有照片
   - `getPhoto(photoId)` - 获取单张照片详情
   - `updatePhoto()` - 更新照片的供应商信息
   - `addSupplierInfo()` - 添加/更新供应商信息（名称+Logo）
   - `deletePhoto()` - 删除照片（同时删除Storage文件和数据库记录）
   - `uploadSupplierLogo()` - 上传供应商Logo到Storage
   - `getPhotosByUser()` - 获取用户上传的所有照片

2. **lib/features/photo/services/image_helper_service.dart** ✅ 新增
   - `pickFromGallery()` - 从相册选择照片并压缩
   - `pickFromCamera()` - 拍照并压缩
   - `compressImage()` - 压缩图片（质量85%，最大1920px，确保<2MB）
   - `getImageSize()` - 检查图片文件大小
   - `isImageTooLarge()` - 判断图片是否超过指定大小

### Provider层
3. **lib/features/photo/providers/photo_provider.dart** ✅ 已存在（无需修改）
   - `photosProvider(boothId)` - 按摊位ID过滤照片，支持Realtime订阅
   - `photoProvider(photoId)` - 获取单张照片
   - 自动订阅Supabase Realtime，数据变化时自动刷新

### 测试文件
4. **test/services/photo_service_test.dart** ✅ 新增
   - 完整的单元测试覆盖（使用mocktail）
   - 测试照片上传流程（选择→压缩→上传→保存记录）
   - 测试供应商信息添加和更新
   - 测试照片删除（同时删除Storage和数据库）
   - 测试按摊位过滤功能
   - 测试数据隔离
   - 测试文件路径格式验证

5. **test/providers/photo_provider_test.dart** ✅ 新增
   - Provider Family工作正常
   - Realtime订阅测试
   - 状态更新测试
   - 不同boothId创建独立Provider实例
   - Provider dispose时取消订阅
   - 错误处理测试

6. **test/services/image_helper_service_test.dart** ✅ 新增
   - 图片选择和压缩测试框架（需要集成测试环境）

### 依赖更新
7. **pubspec.yaml** ✅ 更新
   - 新增 `flutter_image_compress: ^2.0.0`
   - 新增 `path_provider: ^2.1.0`
   - 新增 `mocktail: ^1.0.0`（用于测试）
   - 已有 `image_picker: ^1.0.0`
   - 已有 `uuid: ^4.0.0`

## 核心功能要点

### 1. 照片上传流程
```dart
// 1. 使用ImageHelperService选择并压缩照片
final imageHelper = ImageHelperService();
final compressedFile = await imageHelper.pickFromGallery(); // 或 pickFromCamera()

// 2. 上传到Supabase Storage并创建数据库记录
final photo = await photoService.uploadPhoto(
  photoFile: compressedFile!,
  boothId: 'booth-id',
  teamId: 'team-id',
  uploadedBy: 'user-id',
  supplierName: 'Optional Supplier', // 可选
  supplierLogoUrl: 'Optional Logo URL', // 可选
);
```

### 2. 文件路径格式
- **照片**: `{team_id}/{booth_id}/{timestamp}_{uuid}.jpg`
  - 例: `team-789/booth-123/1234567890_abc-def-ghi.jpg`
- **供应商Logo**: `suppliers/{timestamp}_{uuid}.jpg`
  - 例: `suppliers/1234567890_xyz-abc-def.jpg`

### 3. 照片压缩策略
- **第一次压缩**: 质量85%，最大宽度1920px
- **如果>2MB**: 质量70%，最大宽度1920px
- **如果还>2MB**: 质量50%，最大宽度1280px
- 确保最终文件在Supabase免费版2MB限制内

### 4. 供应商信息管理
```dart
// 上传供应商Logo
final logoUrl = await photoService.uploadSupplierLogo(logoFile);

// 为照片添加供应商信息
final updatedPhoto = await photoService.addSupplierInfo(
  photoId: 'photo-id',
  supplierName: 'Gucci',
  supplierLogoUrl: logoUrl,
);

// 或使用updatePhoto更新部分信息
final photo = await photoService.updatePhoto(
  photoId: 'photo-id',
  supplierName: 'New Name', // 只更新名称
);
```

### 5. 照片删除（级联删除）
```dart
// 同时删除Storage文件和数据库记录
await photoService.deletePhoto('photo-id');
```

### 6. Realtime同步
```dart
// Provider自动订阅Realtime，数据变化时自动刷新
final photosAsync = ref.watch(photosProvider(boothId));

photosAsync.when(
  data: (photos) => ListView.builder(...),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);
```

## 数据库Schema

```sql
CREATE TABLE photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booth_id UUID REFERENCES booths(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  supplier_name TEXT,
  supplier_logo_url TEXT,
  uploaded_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 索引优化
CREATE INDEX idx_photos_booth_id ON photos(booth_id);
CREATE INDEX idx_photos_uploaded_by ON photos(uploaded_by);
CREATE INDEX idx_photos_created_at ON photos(created_at DESC);
```

## Supabase Storage配置

### 创建Storage Bucket
```sql
-- 在Supabase Dashboard创建Storage Bucket
-- Bucket名称: photos
-- Public: true (需要公开访问照片URL)
-- File size limit: 2MB
-- Allowed MIME types: image/jpeg, image/png
```

### Storage路径结构
```
photos/
├── {team_id}/
│   ├── {booth_id}/
│   │   ├── 1234567890_uuid1.jpg
│   │   ├── 1234567891_uuid2.jpg
│   │   └── ...
│   └── ...
└── suppliers/
    ├── 1234567890_uuid1.jpg
    ├── 1234567891_uuid2.jpg
    └── ...
```

## 测试覆盖情况

### PhotoService测试 (test/services/photo_service_test.dart)
- ✅ 上传照片（不含供应商信息）
- ✅ 上传照片（含供应商信息）
- ✅ 文件路径格式验证
- ✅ 上传失败异常处理
- ✅ 按摊位ID获取照片列表
- ✅ 摊位无照片返回空列表
- ✅ 数据隔离测试（不同摊位）
- ✅ 获取单张照片详情
- ✅ 照片不存在返回null
- ✅ 更新供应商名称
- ✅ 更新供应商Logo
- ✅ 同时更新名称和Logo
- ✅ 添加供应商信息
- ✅ 只添加名称（无Logo）
- ✅ 删除照片（Storage+数据库）
- ✅ 删除不存在的照片异常
- ✅ 上传供应商Logo
- ✅ Logo文件路径格式验证

### PhotoProvider测试 (test/providers/photo_provider_test.dart)
- ✅ Provider Family按boothId过滤
- ✅ 不同boothId创建独立实例
- ✅ 初始化时订阅Realtime
- ✅ Realtime更新自动刷新
- ✅ Provider dispose取消订阅
- ✅ 加载失败错误状态
- ✅ 手动refresh刷新
- ✅ photoProvider获取单张照片
- ✅ photoProvider照片不存在返回null

## 使用示例

### 在UI中使用
```dart
class PhotoUploadScreen extends ConsumerWidget {
  final String boothId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photosProvider(boothId));
    final photoService = ref.read(photoServiceProvider);
    final imageHelper = ImageHelperService();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 1. 选择并压缩照片
          final file = await imageHelper.pickFromGallery();
          if (file == null) return;

          // 2. 上传照片
          try {
            await photoService.uploadPhoto(
              photoFile: file,
              boothId: boothId,
              teamId: currentTeamId,
              uploadedBy: currentUserId,
            );
            // Provider会自动通过Realtime刷新
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: $e')),
            );
          }
        },
        child: Icon(Icons.add_a_photo),
      ),
      body: photosAsync.when(
        data: (photos) => GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoDetailScreen(photoId: photo.id),
                ),
              ),
              onLongPress: () async {
                // 删除照片
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Delete photo?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await photoService.deletePhoto(photo.id);
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: photo.url,
                    fit: BoxFit.cover,
                  ),
                  if (photo.supplierName != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: EdgeInsets.all(4),
                        child: Text(
                          photo.supplierName!,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
```

## 后续步骤

### 1. 运行测试
```bash
flutter pub get
flutter test test/services/photo_service_test.dart
flutter test test/providers/photo_provider_test.dart
```

### 2. Supabase配置
- 在Supabase Dashboard创建`photos` Storage Bucket
- 设置为Public访问
- 配置文件大小限制为2MB
- 设置允许的MIME类型：image/jpeg, image/png

### 3. 数据库表已存在
- photos表已创建（根据任务背景）
- 确认有booth_id外键约束
- 确认有uploaded_by外键约束

### 4. 集成到现有UI
- PhotoGridScreen已存在
- PhotoDetailScreen已存在
- 需要在这些Screen中集成新的PhotoService方法

## 注意事项

1. **文件大小限制**: Supabase免费版限制2MB，ImageHelperService确保压缩后不超过此限制
2. **数据隔离**: 照片通过booth_id严格隔离，不同摊位的照片互不干扰
3. **级联删除**: 删除照片时必须同时删除Storage文件和数据库记录
4. **Realtime同步**: Provider自动订阅数据变化，无需手动刷新
5. **供应商信息可选**: 照片上传时可以不填供应商信息，后续可通过addSupplierInfo添加
6. **错误处理**: 所有方法都有适当的错误处理和异常抛出

## 技术栈
- Flutter 3.0+
- Supabase (PostgreSQL + Storage + Realtime)
- Riverpod (状态管理)
- image_picker (照片选择)
- flutter_image_compress (图片压缩)
- mocktail (测试Mock)
