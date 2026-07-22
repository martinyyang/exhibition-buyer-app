import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../core/utils/responsive.dart';
import '../models/photo.dart';

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
  bool _isLoading = false;
  bool _isUploading = false;
  final List<Photo> _photos = []; // TODO: 从Provider获取

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 加载照片列表
      // final photoService = ref.read(photoServiceProvider);
      // final photos = await photoService.getPhotos(widget.boothId);
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // TODO: 调用相机拍照
      // final picker = ImagePicker();
      // final photo = await picker.pickImage(source: ImageSource.camera);
      // if (photo != null) {
      //   final photoService = ref.read(photoServiceProvider);
      //   await photoService.uploadPhoto(widget.boothId, photo);
      //   await _loadPhotos();
      // }
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('照片上传成功')),
        );
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

  void _onPhotoTap(Photo photo) {
    // TODO: 导航到照片详情页
    // context.go('/photo-detail', extra: photo.id);
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
    // TODO: 更新供应商信息
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('供应商信息已更新')),
    );
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
    // TODO: 删除照片
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('照片已删除')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('照片'),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _photos.isEmpty
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
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _onPhotoTap(photo),
                        onLongPress: () => _onPhotoLongPress(photo),
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
                                      Text(
                                        '0个旗子', // TODO: 显示实际旗子数量
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
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
                  },
                ),
      floatingActionButton: _isUploading
          ? const FloatingActionButton(
              onPressed: null,
              child: LoadingIndicator(),
            )
          : FloatingActionButton(
              onPressed: _takePhoto,
              tooltip: '拍照',
              child: const Icon(Icons.camera_alt),
            ),
    );
  }
}
