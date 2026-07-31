import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../core/utils/responsive.dart';
import '../models/photo.dart';
import '../services/image_helper_service.dart';
import '../providers/photo_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/safe_back_button.dart';
import '../../flag/providers/flag_provider.dart';

class PhotoGridScreen extends ConsumerStatefulWidget {
  final String boothId;

  const PhotoGridScreen({
    super.key,
    required this.boothId,
  });

  @override
  ConsumerState<PhotoGridScreen> createState() => _PhotoGridScreenState();
}

class _PhotoGridScreenState extends ConsumerState<PhotoGridScreen> {
  bool _isUploading = false;

  Future<void> _takePhoto() async {
    if (kIsWeb) {
      // Web 端：直接打开文件选择器
      await _pickImageFromGallery();
    } else {
      // 移动端：显示相机/相册选择对话框
      await _showImageSourceDialog();
    }
  }

  /// Web 端和移动端相册选择
  Future<void> _pickImageFromGallery() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final pickedFile = await imageHelper.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        final photoService = ref.read(photoServiceProvider);
        final userData = await ref.read(currentUserDataProvider.future);
        final authState = ref.read(currentUserProvider);
        final user = authState.asData?.value.session?.user;
        final teamId = userData?.teamId;

        if (user == null || teamId == null) {
          throw Exception('用户未登录或未加入团队');
        }

        await photoService.uploadPhoto(
          photoFile: pickedFile,
          boothId: widget.boothId,
          teamId: teamId,
          uploadedBy: user.id,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('照片上传成功')),
          );

          // 手动刷新照片列表（Realtime 未启用时的临时方案）
          ref.read(photosProvider(widget.boothId).notifier).refresh();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// 移动端：相机拍照
  Future<void> _pickImageFromCamera() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final pickedFile = await imageHelper.pickImage(
        source: ImageSource.camera,
      );

      if (pickedFile != null) {
        final photoService = ref.read(photoServiceProvider);
        final userData = await ref.read(currentUserDataProvider.future);
        final authState = ref.read(currentUserProvider);
        final user = authState.asData?.value.session?.user;
        final teamId = userData?.teamId;

        if (user == null || teamId == null) {
          throw Exception('用户未登录或未加入团队');
        }

        await photoService.uploadPhoto(
          photoFile: pickedFile,
          boothId: widget.boothId,
          teamId: teamId,
          uploadedBy: user.id,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('照片上传成功')),
          );

          // 手动刷新照片列表（Realtime 未启用时的临时方案）
          ref.read(photosProvider(widget.boothId).notifier).refresh();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// 移动端：显示图片来源选择对话框
  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('拍照'),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromCamera();
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('从相册选择'),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
          ),
        ],
      ),
    );
  }

  void _onPhotoTap(Photo photo) {
    context.push('/photos/${photo.id}');
  }

  void _onPhotoLongPress(Photo photo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('添加供应商信息'),
            onTap: () {
              Navigator.pop(context);
              _showSupplierDialog(photo);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('删除', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeletePhoto(photo);
            },
          ),
        ],
      ),
    );
  }

  void _showSupplierDialog(Photo photo) {
    final nameController = TextEditingController(text: photo.supplierName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('供应商信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '供应商名称',
                hintText: '例如：LV专柜',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '供应商Logo（可选）',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: 上传供应商Logo
              },
              icon: const Icon(Icons.upload),
              label: const Text('上传Logo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateSupplierInfo(photo, nameController.text);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSupplierInfo(Photo photo, String supplierName) async {
    try {
      final photoService = ref.read(photoServiceProvider);
      await photoService.updatePhoto(
        photoId: photo.id,
        supplierName: supplierName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('供应商信息已更新')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e')),
        );
      }
    }
  }

  void _confirmDeletePhoto(Photo photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这张照片吗？\n所有标注也会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePhoto(photo);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePhoto(Photo photo) async {
    try {
      final photoService = ref.read(photoServiceProvider);
      await photoService.deletePhoto(photo.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('照片已删除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(photosProvider(widget.boothId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('照片'),
        leading: const SafeBackButton(fallbackPath: '/events'),
      ),
      body: photosAsync.when(
        data: (photos) => photos.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无照片',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '点击右下角相机按钮拍照',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.getGridColumns(context),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return _PhotoCard(
                    photo: photo,
                    onTap: () => _onPhotoTap(photo),
                    onLongPress: () => _onPhotoLongPress(photo),
                  );
                },
              ),
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(photosProvider(widget.boothId)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isUploading
          ? const FloatingActionButton(
              onPressed: null,
              child: LoadingIndicator(),
            )
          : FloatingActionButton(
              onPressed: _takePhoto,
              tooltip: kIsWeb ? '上传照片' : '拍照',
              child: Icon(kIsWeb ? Icons.upload_file : Icons.camera_alt),
            ),
    );
  }
}

class _PhotoCard extends ConsumerWidget {
  final Photo photo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PhotoCard({
    required this.photo,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagCountAsync = ref.watch(photoFlagCountProvider(photo.id));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: photo.url,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: LoadingIndicator()),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photo.supplierName != null)
                    Text(
                      photo.supplierName!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.flag, size: 14),
                      const SizedBox(width: 4),
                      flagCountAsync.when(
                        data: (count) => Text(
                          '$count个旗子',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        loading: () => Text(
                          '...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        error: (_, __) => Text(
                          '0个旗子',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
