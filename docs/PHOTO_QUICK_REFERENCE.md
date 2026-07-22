# Photo Feature Quick Reference

## Service Methods Overview

### PhotoService

```dart
// 上传照片
Future<Photo> uploadPhoto({
  required File photoFile,
  required String boothId,
  required String teamId,
  required String uploadedBy,
  String? supplierName,
  String? supplierLogoUrl,
})

// 获取摊位照片列表
Future<List<Photo>> getPhotos(String boothId)

// 获取单张照片
Future<Photo?> getPhoto(String photoId)

// 更新照片信息
Future<Photo> updatePhoto({
  required String photoId,
  String? supplierName,
  String? supplierLogoUrl,
})

// 添加供应商信息
Future<Photo> addSupplierInfo({
  required String photoId,
  required String supplierName,
  String? supplierLogoUrl,
})

// 删除照片（Storage + DB）
Future<void> deletePhoto(String photoId)

// 上传供应商Logo
Future<String> uploadSupplierLogo(File logoFile)

// 获取用户上传的照片
Future<List<Photo>> getPhotosByUser(String userId)
```

### ImageHelperService

```dart
// 从相册选择照片（自动压缩）
Future<File?> pickFromGallery()

// 拍照（自动压缩）
Future<File?> pickFromCamera()

// 压缩图片
Future<File?> compressImage(File imageFile)

// 获取图片大小（字节）
Future<int> getImageSize(File imageFile)

// 检查图片是否过大
Future<bool> isImageTooLarge(File imageFile, {double maxSizeMB = 2.0})
```

## Provider Usage

```dart
// 获取摊位照片列表（自动Realtime同步）
final photosAsync = ref.watch(photosProvider(boothId));

// 获取单张照片
final photoAsync = ref.watch(photoProvider(photoId));

// 手动刷新
ref.read(photosProvider(boothId).notifier).refresh();
```

## Common Use Cases

### 1. 上传照片

```dart
// Step 1: 选择并压缩照片
final imageHelper = ImageHelperService();
final file = await imageHelper.pickFromGallery();

if (file == null) return;

// Step 2: 上传
final photoService = ref.read(photoServiceProvider);
try {
  final photo = await photoService.uploadPhoto(
    photoFile: file,
    boothId: currentBoothId,
    teamId: currentTeamId,
    uploadedBy: currentUserId,
  );
  print('Photo uploaded: ${photo.id}');
} catch (e) {
  print('Upload failed: $e');
}
```

### 2. 添加供应商信息

```dart
// 方式1: 上传时直接提供
await photoService.uploadPhoto(
  photoFile: file,
  boothId: boothId,
  teamId: teamId,
  uploadedBy: userId,
  supplierName: 'Gucci',
  supplierLogoUrl: logoUrl,
);

// 方式2: 后续添加
await photoService.addSupplierInfo(
  photoId: photoId,
  supplierName: 'Gucci',
  supplierLogoUrl: logoUrl,
);

// 方式3: 部分更新
await photoService.updatePhoto(
  photoId: photoId,
  supplierName: 'New Name', // 只更新名称
);
```

### 3. 上传供应商Logo

```dart
final logoFile = await imageHelper.pickFromGallery();
if (logoFile != null) {
  final logoUrl = await photoService.uploadSupplierLogo(logoFile);
  
  // 然后关联到照片
  await photoService.updatePhoto(
    photoId: photoId,
    supplierLogoUrl: logoUrl,
  );
}
```

### 4. 删除照片

```dart
try {
  await photoService.deletePhoto(photoId);
  print('Photo deleted successfully');
} catch (e) {
  print('Delete failed: $e');
}
```

### 5. 显示照片列表

```dart
class PhotoListWidget extends ConsumerWidget {
  final String boothId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photosProvider(boothId));

    return photosAsync.when(
      data: (photos) => GridView.builder(
        itemCount: photos.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemBuilder: (context, index) {
          final photo = photos[index];
          return CachedNetworkImage(
            imageUrl: photo.url,
            fit: BoxFit.cover,
          );
        },
      ),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

## Storage Structure

```
photos/
├── {team_id}/
│   ├── {booth_id}/
│   │   ├── 1234567890_abc-def.jpg
│   │   └── 1234567891_xyz-123.jpg
│   └── ...
└── suppliers/
    ├── 1234567890_logo1.jpg
    └── 1234567891_logo2.jpg
```

## File Size Limits

- **Target**: < 2MB (Supabase free tier limit)
- **Compression**: Automatic multi-stage (85% → 70% → 50%)
- **Max Dimensions**: 1920x1080 (first attempt)
- **Fallback**: 1280x720 (if still too large)

## Testing

```bash
# Run all photo tests
flutter test test/services/photo_service_test.dart
flutter test test/providers/photo_provider_test.dart

# Run specific test
flutter test test/services/photo_service_test.dart --name "上传照片"
```

## Troubleshooting

### Upload fails
- Check file size (must be < 2MB after compression)
- Verify Supabase Storage bucket 'photos' exists
- Check bucket is set to public
- Verify user has upload permissions

### Photos not appearing
- Check Provider is watching correct boothId
- Verify Realtime subscription is active
- Check database record was created
- Verify Storage file was uploaded

### Delete fails
- Check photo exists in database
- Verify URL format is correct
- Check Storage permissions
- Ensure cascade delete is enabled on booth_id foreign key

## Database Schema

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
```
