import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../flag/widgets/flag_table.dart';
import '../../flag/models/flag.dart';
import '../models/photo.dart';

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
  bool _isLoading = false;
  Photo? _photo;
  final List<Flag> _flags = []; // TODO: 从Provider获取
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 加载照片和旗子数据
      // final photoService = ref.read(photoServiceProvider);
      // final photo = await photoService.getPhoto(widget.photoId);
      // final flagService = ref.read(flagServiceProvider);
      // final flags = await flagService.getFlags(widget.photoId);
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

  void _onPhotoTap(TapDownDetails details, Size imageSize) {
    if (!widget.isRemoteView) return; // 只有远程端可以插旗

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);

    // 转换为相对坐标（0-1）
    final relativeX = localPosition.dx / imageSize.width;
    final relativeY = localPosition.dy / imageSize.height;

    _createFlag(relativeX, relativeY);
  }

  Future<void> _createFlag(double x, double y) async {
    try {
      // TODO: 创建新旗子
      // final flagService = ref.read(flagServiceProvider);
      // await flagService.createFlag(widget.photoId, x, y);
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('标记已添加')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }

  void _onFlagRowTap(Flag flag, Size imageSize) {
    // 点击表格行，聚焦到对应旗子位置
    final targetX = flag.positionX * imageSize.width;
    final targetY = flag.positionY * imageSize.height;

    // 计算变换矩阵，使旗子居中
    final matrix = Matrix4.identity()
      ..translate(-targetX + imageSize.width / 2, -targetY + imageSize.height / 2)
      ..scale(2.0); // 放大2倍

    _transformationController.value = matrix;
  }

  void _onFlagLongPress(Flag flag) {
    if (!widget.isRemoteView) return; // 只有远程端可以删除旗子

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
    // TODO: 删除旗子
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已删除旗子 #${flag.number}')),
    );
  }

  Widget _buildPhotoWithFlags(Size imageSize) {
    return Stack(
      children: [
        // 照片
        if (_photo != null)
          CachedNetworkImage(
            imageUrl: _photo!.url,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(child: LoadingIndicator()),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),

        // 旗子标记
        ..._flags.map((flag) {
          return Positioned(
            left: flag.positionX * imageSize.width - 20,
            top: flag.positionY * imageSize.height - 40,
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
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // 上半部分：照片
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTapDown: widget.isRemoteView
                ? (details) => _onPhotoTap(details, const Size(400, 300))
                : null,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              child: _buildPhotoWithFlags(const Size(400, 300)),
            ),
          ),
        ),

        const Divider(height: 1),

        // 下半部分：Flag表格
        Expanded(
          flex: 2,
          child: _flags.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        widget.isRemoteView ? '点击照片标记商品' : '等待远程团队标记',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : FlagTable(
                  flags: _flags,
                  isRemoteView: widget.isRemoteView,
                  onRowTap: (flag) => _onFlagRowTap(flag, const Size(400, 300)),
                ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // 左侧：照片
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTapDown: widget.isRemoteView
                ? (details) => _onPhotoTap(details, const Size(800, 600))
                : null,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: _buildPhotoWithFlags(const Size(800, 600)),
              ),
            ),
          ),
        ),

        const VerticalDivider(width: 1),

        // 右侧：Flag表格
        Expanded(
          flex: 1,
          child: _flags.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        widget.isRemoteView ? '点击照片标记商品' : '等待远程团队标记',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : FlagTable(
                  flags: _flags,
                  isRemoteView: widget.isRemoteView,
                  onRowTap: (flag) => _onFlagRowTap(flag, const Size(800, 600)),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRemoteView ? '标注商品' : '查看报价'),
        actions: [
          if (_photo?.supplierName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  _photo!.supplierName!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                // Web端（宽度>900）使用左右布局，移动端使用上下布局
                if (constraints.maxWidth > 900) {
                  return _buildDesktopLayout();
                } else {
                  return _buildMobileLayout();
                }
              },
            ),
    );
  }
}
