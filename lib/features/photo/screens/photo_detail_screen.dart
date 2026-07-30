import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../flag/widgets/flag_table.dart';
import '../../flag/models/flag.dart';
import '../../flag/providers/flag_provider.dart';
import '../../flag/services/flag_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/photo.dart';
import '../providers/photo_provider.dart';
import '../../../shared/widgets/safe_back_button.dart';

class PhotoDetailScreen extends ConsumerStatefulWidget {
  final String photoId;
  final bool isRemoteView;

  const PhotoDetailScreen({
    super.key,
    required this.photoId,
    this.isRemoteView = false,
  });

  @override
  ConsumerState<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends ConsumerState<PhotoDetailScreen> {
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _imageKey = GlobalKey();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Size? _getImageSize() {
    final RenderBox? renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size;
  }

  void _onPhotoTap(TapDownDetails details) {
    // 买手和远程用户都可以插旗标记
    final imageSize = _getImageSize();
    if (imageSize == null) return;

    final RenderBox box =
        _imageKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);

    // 转换为相对坐标（0-1）
    final relativeX = localPosition.dx / imageSize.width;
    final relativeY = localPosition.dy / imageSize.height;

    _createFlag(relativeX, relativeY);
  }

  Future<void> _createFlag(double x, double y) async {
    try {
      final flagService = ref.read(flagServiceProvider);
      final supabaseService = ref.read(supabaseServiceProvider);
      final userId = supabaseService.client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('用户未登录');
      }

      await flagService.createFlag(
        photoId: widget.photoId,
        positionX: x,
        positionY: y,
        createdBy: userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('标记已添加')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }

  void _onFlagRowTap(Flag flag) {
    // 点击表格行，聚焦到对应旗子位置
    final imageSize = _getImageSize();
    if (imageSize == null) return;

    final targetX = flag.positionX * imageSize.width;
    final targetY = flag.positionY * imageSize.height;

    // 计算变换矩阵，使旗子居中
    final matrix = Matrix4.identity()
      ..translate(
          -targetX + imageSize.width / 2, -targetY + imageSize.height / 2)
      ..scale(2.0); // 放大2倍

    _transformationController.value = matrix;
  }

  void _onFlagLongPress(Flag flag) {
    // 买手和远程用户都可以删除旗子

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除标记'),
        content: Text('确定要删除旗子 #${flag.number} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFlag(flag);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFlag(Flag flag) async {
    try {
      final flagService = ref.read(flagServiceProvider);
      await flagService.deleteFlag(flag.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除旗子 #${flag.number}')),
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

  Widget _buildPhotoWithFlags(Photo? photo, List<Flag> flags) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          key: _imageKey,
          children: [
            // 照片
            if (photo != null)
              CachedNetworkImage(
                imageUrl: photo.url,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const Center(child: LoadingIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),

            // 旗子标记
            ...flags.map((flag) {
              return Positioned(
                left: flag.positionX * constraints.maxWidth - 20,
                top: flag.positionY * constraints.maxHeight - 40,
                child: GestureDetector(
                  onLongPress: () => _onFlagLongPress(flag),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: flag.needsAttention ? Colors.red : Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${flag.number}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      // 旗杆
                      Container(
                        width: 2,
                        height: 20,
                        color: flag.needsAttention ? Colors.red : Colors.blue,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildMobileLayout(Photo? photo, List<Flag> flags) {
    return Column(
      children: [
        // 上半部分：照片
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTapDown: (details) => _onPhotoTap(details),
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              child: _buildPhotoWithFlags(photo, flags),
            ),
          ),
        ),

        const Divider(height: 1),

        // 下半部分：Flag表格
        Expanded(
          flex: 2,
          child: flags.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        '点击照片标记商品',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : FlagTable(
                  flags: flags,
                  isRemoteView: widget.isRemoteView,
                  onRowTap: (flag) => _onFlagRowTap(flag),
                ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(Photo? photo, List<Flag> flags) {
    return Row(
      children: [
        // 左侧：照片
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTapDown: (details) => _onPhotoTap(details),
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: _buildPhotoWithFlags(photo, flags),
              ),
            ),
          ),
        ),

        const VerticalDivider(width: 1),

        // 右侧：Flag表格
        Expanded(
          flex: 1,
          child: flags.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        '点击照片标记商品',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : FlagTable(
                  flags: flags,
                  isRemoteView: widget.isRemoteView,
                  onRowTap: (flag) => _onFlagRowTap(flag),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoAsync = ref.watch(photoProvider(widget.photoId));
    final flagsAsync = ref.watch(flagsProvider(widget.photoId));

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(fallbackPath: '/events'),
        title: Text(widget.isRemoteView ? '标注商品' : '查看报价'),
        actions: [
          photoAsync.whenOrNull(
                data: (photo) {
                  if (photo?.supplierName != null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: Text(
                          photo!.supplierName!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: photoAsync.when(
        data: (photo) {
          return flagsAsync.when(
            data: (flags) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  // Web端（宽度>900）使用左右布局，移动端使用上下布局
                  if (constraints.maxWidth > 900) {
                    return _buildDesktopLayout(photo, flags);
                  } else {
                    return _buildMobileLayout(photo, flags);
                  }
                },
              );
            },
            loading: () => const Center(child: LoadingIndicator()),
            error: (error, stack) => Center(
              child: Text('加载失败: $error'),
            ),
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(
          child: Text('加载失败: $error'),
        ),
      ),
    );
  }
}
