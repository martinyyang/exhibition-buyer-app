import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../flag/widgets/flag_table.dart';
import '../../flag/models/flag.dart';
import '../../flag/providers/flag_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../formula/providers/formula_provider.dart';
import '../../formula/services/formula_calculator.dart';
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
  static const double _gridCellSizePercent = 0.015; // 1.5% of container size
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _imageKey = GlobalKey();
  ui.Image? _loadedImage;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _onPhotoTap(TapDownDetails details, Size containerSize) {
    if (_loadedImage == null) return;

    final localPosition = details.localPosition;

    // 计算图片在容器中的实际显示尺寸和位置（BoxFit.contain效果）
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

    // 检查点击是否在图片显示区域内
    if (localPosition.dx < offsetX ||
        localPosition.dx > offsetX + displayWidth ||
        localPosition.dy < offsetY ||
        localPosition.dy > offsetY + displayHeight) {
      return; // 点击在图片外，不处理
    }

    // 转换为图片内的相对坐标
    final imageLocalX = localPosition.dx - offsetX;
    final imageLocalY = localPosition.dy - offsetY;

    // 应用基于图片显示尺寸的网格对齐
    final gridCellSize = displayWidth * _gridCellSizePercent;
    final snappedX = (imageLocalX / gridCellSize).round() * gridCellSize;
    final snappedY = (imageLocalY / gridCellSize).round() * gridCellSize;

    // 转换为相对坐标（0-1）
    final relativeX = (snappedX / displayWidth).clamp(0.0, 1.0);
    final relativeY = (snappedY / displayHeight).clamp(0.0, 1.0);

    _createFlag(relativeX, relativeY);
  }

  Future<void> _createFlag(double x, double y) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final flagService = ref.read(flagServiceProvider);
      final supabaseService = ref.read(supabaseServiceProvider);
      final userId = supabaseService.client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception(l10n.userNotInTeam);
      }

      await flagService.createFlag(
        photoId: widget.photoId,
        positionX: x,
        positionY: y,
        createdBy: userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.flagAdded)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addFailed(e.toString()))),
        );
      }
    }
  }

  void _onFlagRowTap(Flag flag) {
    // 点击表格行，聚焦到对应旗子位置
    if (_loadedImage == null) return;

    // 获取容器大小
    final RenderBox? renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final containerSize = renderBox.size;

    // 计算图片在容器中的实际显示尺寸和位置（BoxFit.contain效果）
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

    // 计算旗子在容器中的实际像素位置
    final flagX = offsetX + flag.positionX * displayWidth;
    final flagY = offsetY + flag.positionY * displayHeight;

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
    final l10n = AppLocalizations.of(context)!;
    // 买手和远程用户都可以删除旗子

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteFlag),
        content: Text(l10n.confirmDeleteFlagMessage(flag.number)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFlagDirect(flag);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFlagDirect(Flag flag) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final flagService = ref.read(flagServiceProvider);
      await flagService.deleteFlag(flag.id);

      // 刷新旗子列表
      ref.invalidate(flagsProvider(widget.photoId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.flagDeletedSuccess(flag.number))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deleteFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _updateFlagPrice(Flag flag, double price) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final flagService = ref.read(flagServiceProvider);
      final userData = await ref.read(currentUserDataProvider.future);
      final teamId = userData?.teamId;

      // 获取团队的当前公式
      String? formula;
      double? priceConverted;

      if (teamId != null) {
        // 等待公式加载完成
        await ref.read(currentFormulaProvider(teamId).notifier).refresh();
        final formulaAsync = ref.read(currentFormulaProvider(teamId));
        formula = formulaAsync.valueOrNull;

        // 如果有公式，计算换算价格
        if (formula != null && formula.isNotEmpty) {
          try {
            priceConverted = FormulaCalculator.calculate(formula, price);
          } catch (e) {
            // 公式计算失败，不更新换算价格
          }
        }
      }

      // 更新价格和换算价格
      await flagService.updateFlag(
        flagId: flag.id,
        priceRmb: price,
        priceConverted: priceConverted,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.updatePriceFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _updateFlagTargetPrice(Flag flag, double targetPrice) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final flagService = ref.read(flagServiceProvider);
      await flagService.updateFlag(
        flagId: flag.id,
        targetPrice: targetPrice,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.updateTargetPriceFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _togglePurchaseStatus(Flag flag, bool isPurchased) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final flagService = ref.read(flagServiceProvider);
      await flagService.updateFlag(
        flagId: flag.id,
        isPurchased: isPurchased,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deleteFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _deleteFlag(Flag flag) async {
    final l10n = AppLocalizations.of(context)!;

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteFlagMessage(flag.number)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final flagService = ref.read(flagServiceProvider);
      await flagService.deleteFlag(flag.id);

      // 刷新旗子列表
      ref.invalidate(flagsProvider(widget.photoId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.flagDeletedSuccess(flag.number))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deleteFailed(e.toString()))),
        );
      }
    }
  }

  Widget _buildPhotoWithFlags(Photo? photo, List<Flag> flags) {
    if (photo == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return GestureDetector(
          onTapDown: (details) => _onPhotoTap(details, containerSize),
          child: Stack(
            children: [
              // 照片
              Positioned.fill(
                key: _imageKey,
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
                    containerSize.width / containerSize.height;

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

                // 限制旗子坐标在有效范围内（0-1），防止显示到画面外
                final clampedX = flag.positionX.clamp(0.0, 1.0);
                final clampedY = flag.positionY.clamp(0.0, 1.0);

                // 根据图片实际显示区域计算旗子位置
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
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(Photo? photo, List<Flag> flags) {
    final l10n = AppLocalizations.of(context)!;
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
                        l10n.tapToMarkProduct,
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
                  onPurchaseToggle: (flag, isPurchased) =>
                      _togglePurchaseStatus(flag, isPurchased),
                  onDelete: (flag) => _deleteFlag(flag),
                  onConvertedPriceTap: () => context.push('/formula'),
                ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(Photo? photo, List<Flag> flags) {
    final l10n = AppLocalizations.of(context)!;
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
                  tooltip: l10n.resetView,
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
                        l10n.tapToMarkProduct,
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
                  onPurchaseToggle: (flag, isPurchased) =>
                      _togglePurchaseStatus(flag, isPurchased),
                  onDelete: (flag) => _deleteFlag(flag),
                  onConvertedPriceTap: () => context.push('/formula'),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photoAsync = ref.watch(photoProvider(widget.photoId));
    final flagsAsync = ref.watch(flagsProvider(widget.photoId));

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(fallbackPath: '/events'),
        title:
            Text(widget.isRemoteView ? l10n.annotateProducts : l10n.viewQuotes),
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
              child: Text(l10n.loadFailed(error.toString())),
            ),
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(
          child: Text(l10n.loadFailed(error.toString())),
        ),
      ),
    );
  }
}
