import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3, Matrix4;
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
  ui.Image? _loadedImage;

  // 网格系统：每15像素一个格子
  static const double _gridCellSize = 15.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // 获取图片的实际显示尺寸和位置（考虑BoxFit.contain的效果）
  (Size, Offset)? _getActualImageBounds() {
    final RenderBox? renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || _loadedImage == null) return null;

    final containerSize = renderBox.size;
    final imageAspect = _loadedImage!.width / _loadedImage!.height;
    final containerAspect = containerSize.width / containerSize.height;

    double displayWidth, displayHeight, offsetX, offsetY;

    if (imageAspect > containerAspect) {
      // 图片更宽，以宽度为准
      displayWidth = containerSize.width;
      displayHeight = containerSize.width / imageAspect;
      offsetX = 0;
      offsetY = (containerSize.height - displayHeight) / 2;
    } else {
      // 图片更高，以高度为准
      displayHeight = containerSize.height;
      displayWidth = containerSize.height * imageAspect;
      offsetX = (containerSize.width - displayWidth) / 2;
      offsetY = 0;
    }

    return (Size(displayWidth, displayHeight), Offset(offsetX, offsetY));
  }

  // 将像素坐标捕捉到最近的网格点，并转换为0-1相对坐标
  Offset _snapToGrid(Offset pixelPosition, Size imageSize) {
    // 计算图片的网格数量
    final gridCols = (imageSize.width / _gridCellSize).ceil();
    final gridRows = (imageSize.height / _gridCellSize).ceil();

    // 计算点击位置在哪个网格
    final gridX = (pixelPosition.dx / _gridCellSize).round().clamp(0, gridCols);
    final gridY = (pixelPosition.dy / _gridCellSize).round().clamp(0, gridRows);

    // 转换回像素坐标（网格交叉点）
    final snappedPixelX = gridX * _gridCellSize;
    final snappedPixelY = gridY * _gridCellSize;

    // 转换为0-1相对坐标
    final relativeX = (snappedPixelX / imageSize.width).clamp(0.0, 1.0);
    final relativeY = (snappedPixelY / imageSize.height).clamp(0.0, 1.0);

    return Offset(relativeX, relativeY);
  }

  void _onPhotoTap(TapDownDetails details) {
    final bounds = _getActualImageBounds();
    if (bounds == null) return;

    final (imageSize, imageOffset) = bounds;
    final RenderBox box =
        _imageKey.currentContext!.findRenderObject() as RenderBox;

    // 获取相对于图片容器的局部坐标
    final localPosition = box.globalToLocal(details.globalPosition);

    // 应用 InteractiveViewer 变换矩阵的逆矩阵
    final Matrix4 inverseMatrix =
        Matrix4.inverted(_transformationController.value);
    final Vector3 transformed = inverseMatrix.transform3(Vector3(
      localPosition.dx,
      localPosition.dy,
      0,
    ));

    // 减去图片在容器中的偏移量
    final imageLocalX = transformed.x - imageOffset.dx;
    final imageLocalY = transformed.y - imageOffset.dy;

    // 检查点击是否在图片实际区域内
    if (imageLocalX < 0 ||
        imageLocalY < 0 ||
        imageLocalX > imageSize.width ||
        imageLocalY > imageSize.height) {
      return; // 点击在空白区域，忽略
    }

    // 捕捉到网格点并转换为相对坐标
    final snapped = _snapToGrid(
      Offset(imageLocalX, imageLocalY),
      imageSize,
    );

    _createFlag(snapped.dx, snapped.dy);
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
    final bounds = _getActualImageBounds();
    if (bounds == null) return;

    final (imageSize, imageOffset) = bounds;

    // 计算旗子在图片上的实际像素位置
    final flagX = imageOffset.dx + flag.positionX * imageSize.width;
    final flagY = imageOffset.dy + flag.positionY * imageSize.height;

    // 获取容器大小（InteractiveViewer的可视区域）
    final RenderBox? renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final containerSize = renderBox.size;

    // 计算变换矩阵：先缩放2倍，然后平移使旗子居中到容器中心
    final scale = 2.0;
    final matrix = Matrix4.identity()
      ..translate(
        containerSize.width / 2 - flagX * scale,
        containerSize.height / 2 - flagY * scale,
      )
      ..scale(scale);

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

  Future<void> _updateFlagPrice(Flag flag, double price) async {
    try {
      final flagService = ref.read(flagServiceProvider);
      await flagService.updateFlag(
        flagId: flag.id,
        priceRmb: price,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新报价失败: $e')),
        );
      }
    }
  }

  Future<void> _updateFlagTargetPrice(Flag flag, double targetPrice) async {
    try {
      final flagService = ref.read(flagServiceProvider);
      await flagService.updateFlag(
        flagId: flag.id,
        targetPrice: targetPrice,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新目标价失败: $e')),
        );
      }
    }
  }

  Widget _buildPhotoWithFlags(Photo? photo, List<Flag> flags) {
    if (photo == null) return const SizedBox.shrink();

    return GestureDetector(
      onTapDown: (details) => _onPhotoTap(details),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // 照片
              Container(
                key: _imageKey,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: CachedNetworkImage(
                  imageUrl: photo.url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Center(child: LoadingIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  imageBuilder: (context, imageProvider) {
                    // 加载图片以获取原始尺寸
                    imageProvider
                        .resolve(const ImageConfiguration())
                        .addListener(ImageStreamListener((info, _) {
                      if (mounted && _loadedImage == null) {
                        setState(() {
                          _loadedImage = info.image;
                        });
                      }
                    }));
                    return Image(image: imageProvider, fit: BoxFit.contain);
                  },
                ),
              ),

              // 旗子标记
              ...flags.map((flag) {
                if (_loadedImage == null) return const SizedBox.shrink();

                // 计算图片在容器中的实际显示尺寸和位置（BoxFit.contain效果）
                final imageAspect = _loadedImage!.width / _loadedImage!.height;
                final containerAspect =
                    constraints.maxWidth / constraints.maxHeight;

                double displayWidth, displayHeight, offsetX, offsetY;

                if (imageAspect > containerAspect) {
                  // 图片更宽，以宽度为准
                  displayWidth = constraints.maxWidth;
                  displayHeight = constraints.maxWidth / imageAspect;
                  offsetX = 0;
                  offsetY = (constraints.maxHeight - displayHeight) / 2;
                } else {
                  // 图片更高，以高度为准
                  displayHeight = constraints.maxHeight;
                  displayWidth = constraints.maxHeight * imageAspect;
                  offsetX = (constraints.maxWidth - displayWidth) / 2;
                  offsetY = 0;
                }

                // 限制旗子坐标在有效范围内（0-1），防止显示到画面外
                final clampedX = flag.positionX.clamp(0.0, 1.0);
                final clampedY = flag.positionY.clamp(0.0, 1.0);

                // 根据图片实际显示区域计算旗子位置
                // 十字准星中心对齐到点击位置
                final flagColor =
                    flag.needsAttention ? Colors.red : Colors.blue;

                return Positioned(
                  left: offsetX + clampedX * displayWidth - 20,
                  top: offsetY + clampedY * displayHeight - 20,
                  child: GestureDetector(
                    onLongPress: () => _onFlagLongPress(flag),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        children: [
                          // 空心圆圈
                          Center(
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: flagColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          // 横向十字线
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 19,
                            child: Container(
                              height: 2,
                              color: flagColor,
                            ),
                          ),
                          // 纵向十字线
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: 19,
                            child: Container(
                              width: 2,
                              color: flagColor,
                            ),
                          ),
                          // 中心数字（带白色背景）
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '${flag.number}',
                                style: TextStyle(
                                  color: flagColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(Photo? photo, List<Flag> flags) {
    return Column(
      children: [
        // 上半部分：照片（移动端禁用InteractiveViewer避免手势冲突）
        Expanded(
          flex: 3,
          child: _buildPhotoWithFlags(photo, flags),
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
                  onPriceUpdate: (flag, price) => _updateFlagPrice(flag, price),
                  onTargetPriceUpdate: (flag, targetPrice) =>
                      _updateFlagTargetPrice(flag, targetPrice),
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
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: _buildPhotoWithFlags(photo, flags),
              ),
              // 重置视图按钮
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    _transformationController.value = Matrix4.identity();
                  },
                  tooltip: '重置视图',
                  child: const Icon(Icons.refresh, size: 20),
                ),
              ),
            ],
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
                  onPriceUpdate: (flag, price) => _updateFlagPrice(flag, price),
                  onTargetPriceUpdate: (flag, targetPrice) =>
                      _updateFlagTargetPrice(flag, targetPrice),
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
