import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../flag/widgets/flag_table.dart';
import '../../flag/widgets/user_color_legend.dart';
import '../../flag/models/flag.dart';
import '../../flag/providers/flag_provider.dart';
import '../../flag/services/flag_service.dart';
import '../../flag/utils/flag_layout_helper.dart';
import '../../flag/utils/user_color_mapper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../formula/providers/formula_provider.dart';
import '../../formula/services/formula_calculator.dart';
import '../../presence/widgets/online_users_widget.dart';
import '../../presence/mixins/presence_manager_mixin.dart';
import '../models/photo.dart';
import '../providers/photo_provider.dart';
import '../../../shared/widgets/safe_back_button.dart';
import '../../../core/providers/last_viewed_provider.dart';

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

class _PhotoDetailScreenState extends ConsumerState<PhotoDetailScreen>
    with PresenceManagerMixin {
  static const double _gridCellSizePercent = 0.015; // 1.5% of container size
  final TransformationController _transformationController =
      TransformationController();
  final TransformationController _mobileTransformationController =
      TransformationController();
  final GlobalKey _imageKey = GlobalKey();
  ui.Image? _loadedImage;
  bool _areFlagsVisible = true; // 旗子显示状态
  bool _isCreatingFlag = false; // 防止连续点击创建重复旗子

  @override
  String get screenIdentifier => 'photo_detail';

  @override
  Map<String, dynamic>? get screenContext => {'photo_id': widget.photoId};

  @override
  void initState() {
    super.initState();
    // 页面加载完成后记录查看时间
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lastViewedService = ref.read(lastViewedServiceProvider);
      lastViewedService.markPhotoAsViewed(widget.photoId);
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _mobileTransformationController.dispose();
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

    // 防止连续点击创建重复旗子
    if (_isCreatingFlag) return;

    setState(() {
      _isCreatingFlag = true;
    });

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final userId = supabaseService.client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception(l10n.userNotInTeam);
      }

      // 1. 创建临时旗子（立即显示 - 乐观更新）
      final tempId = 'temp_${DateTime.now().microsecondsSinceEpoch}';
      final optimisticFlag = Flag(
        id: tempId,
        createdAt: DateTime.now(),
        photoId: widget.photoId,
        number: 0, // 临时编号（界面显示为"..."）
        positionX: x,
        positionY: y,
        needsAttention: false,
        createdBy: userId,
        updatedAt: DateTime.now(),
      );

      // 2. 立即更新界面（无需等待网络）
      ref
          .read(flagsProvider(widget.photoId).notifier)
          .addOptimistic(optimisticFlag);

      // 3. 异步提交到服务器
      final flagService = ref.read(flagServiceProvider);
      final realFlag = await flagService.createFlag(
        photoId: widget.photoId,
        positionX: x,
        positionY: y,
        createdBy: userId,
      );

      // 4. 替换临时旗子为真实旗子（带真实编号）
      ref
          .read(flagsProvider(widget.photoId).notifier)
          .replaceOptimistic(tempId, realFlag);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.flagAdded)),
        );
      }
    } catch (e) {
      // 5. 失败回滚：移除临时旗子
      final tempId = 'temp_${DateTime.now().microsecondsSinceEpoch}';
      ref.read(flagsProvider(widget.photoId).notifier).removeOptimistic(tempId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingFlag = false;
        });
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
    const scale = 2.0;
    final matrix = Matrix4.identity()
      ..translate(
        containerSize.width / 2 - flagX * scale,
        containerSize.height / 2 - flagY * scale,
      )
      ..scale(scale);

    // 根据屏幕宽度判断是移动端还是桌面端，更新相应的controller
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      _mobileTransformationController.value = matrix;
    } else {
      _transformationController.value = matrix;
    }
  }

  void _zoomIn() {
    // 放大：在当前缩放基础上增加0.5倍
    final currentMatrix = _mobileTransformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();

    // 限制最大缩放为4倍
    if (currentScale >= 4.0) return;

    final newScale = (currentScale + 0.5).clamp(0.5, 4.0);
    final scaleFactor = newScale / currentScale;

    // 获取当前视图中心点
    final RenderBox? renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final containerSize = renderBox.size;
    final centerX = containerSize.width / 2;
    final centerY = containerSize.height / 2;

    // 以视图中心为基准进行缩放
    final newMatrix = Matrix4.identity()
      ..translate(centerX, centerY)
      ..scale(scaleFactor)
      ..translate(-centerX, -centerY)
      ..multiply(currentMatrix);

    _mobileTransformationController.value = newMatrix;
  }

  void _zoomOut() {
    // 缩小：在当前缩放基础上减少0.5倍
    final currentMatrix = _mobileTransformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();

    // 限制最小缩放为0.5倍
    if (currentScale <= 0.5) return;

    final newScale = (currentScale - 0.5).clamp(0.5, 4.0);
    final scaleFactor = newScale / currentScale;

    // 获取当前视图中心点
    final RenderBox? renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final containerSize = renderBox.size;
    final centerX = containerSize.width / 2;
    final centerY = containerSize.height / 2;

    // 以视图中心为基准进行缩放
    final newMatrix = Matrix4.identity()
      ..translate(centerX, centerY)
      ..scale(scaleFactor)
      ..translate(-centerX, -centerY)
      ..multiply(currentMatrix);

    _mobileTransformationController.value = newMatrix;
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

      // 更新价格和换算价格，带冲突检测
      await flagService.updateFlag(
        flagId: flag.id,
        expectedUpdatedAt: flag.updatedAt,
        priceRmb: price,
        priceConverted: priceConverted,
      );
    } on FlagConflictException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: '刷新',
              textColor: Colors.white,
              onPressed: () {
                ref.invalidate(flagsProvider(widget.photoId));
              },
            ),
          ),
        );
      }
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
        expectedUpdatedAt: flag.updatedAt,
        targetPrice: targetPrice,
      );
    } on FlagConflictException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: '刷新',
              textColor: Colors.white,
              onPressed: () {
                ref.invalidate(flagsProvider(widget.photoId));
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.updateTargetPriceFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _updatePurchaseStatus(Flag flag, String? status) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final flagService = ref.read(flagServiceProvider);
      await flagService.updateFlag(
        flagId: flag.id,
        purchaseStatus: status,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deleteFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _updateFinalStatus(Flag flag, String? status) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final flagService = ref.read(flagServiceProvider);
      await flagService.updateFlag(
        flagId: flag.id,
        finalStatus: status,
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

              // 旗子标记（根据可见性状态显示/隐藏，自动处理重叠）
              ...() {
                if (_loadedImage == null) return <Widget>[];

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

                // 使用布局助手计算旗子位置（自动处理重叠）
                final positions = FlagLayoutHelper.calculateLayout(flags);
                final groupInfo = FlagLayoutHelper.getGroupInfo(flags);

                return positions.map((position) {
                  final flag = position.flag;
                  // 根据用户ID分配颜色，紧急标记用红色覆盖
                  final flagColor = flag.needsAttention
                      ? Colors.red
                      : UserColorMapper.getColorForUser(flag.createdBy);

                  // 是否显示连线（从展开位置到原始中心点）
                  final showConnector =
                      position.isGrouped && groupInfo.containsKey(flag.id);

                  return Positioned(
                    left: offsetX + position.x * displayWidth - 20,
                    top: offsetY + position.y * displayHeight - 20,
                    child: Visibility(
                      visible: _areFlagsVisible,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 连线到中心点（仅在分组时显示）
                          if (showConnector)
                            CustomPaint(
                              painter: _FlagConnectorPainter(
                                startX: 20,
                                startY: 20,
                                endX:
                                    (groupInfo[flag.id]!.centerX - position.x) *
                                        displayWidth,
                                endY:
                                    (groupInfo[flag.id]!.centerY - position.y) *
                                        displayHeight,
                                color: flagColor.withOpacity(0.3),
                              ),
                            ),
                          // 旗子标记
                          GestureDetector(
                            key: Key('flag_marker_${flag.id}'),
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
                                        flag.number == 0
                                            ? '...'
                                            : '${flag.number}',
                                        style: TextStyle(
                                          color: flagColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // 分组标记（右上角显示组内数量）
                                  if (position.isGrouped &&
                                      position.groupSize > 1)
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${position.groupSize}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList();
              }(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(Photo? photo, List<Flag> flags) {
    final l10n = AppLocalizations.of(context)!;
    final userData = ref.watch(currentUserDataProvider);
    final teamId = userData.value?.teamId;

    return Column(
      children: [
        // 上半部分：照片（移动端启用InteractiveViewer支持放大）
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _mobileTransformationController,
                minScale: 0.5,
                maxScale: 4.0,
                panEnabled: true,
                scaleEnabled: false, // 禁用双指缩放手势
                child: _buildPhotoWithFlags(photo, flags),
              ),
              // 左上角：谁在看这张照片
              if (teamId != null)
                Positioned(
                  top: 16,
                  left: 16,
                  child: ScreenActivityIndicator(
                    teamId: teamId,
                    screen: 'photo_detail',
                    context: {'photo_id': widget.photoId},
                  ),
                ),
              // 右上角按钮组
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    // 重置视图按钮
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'reset_mobile_view',
                      onPressed: () {
                        _mobileTransformationController.value =
                            Matrix4.identity();
                      },
                      tooltip: l10n.resetView,
                      child: const Icon(Icons.refresh, size: 20),
                    ),
                    const SizedBox(height: 8),
                    // 放大按钮
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'zoom_in',
                      onPressed: _zoomIn,
                      tooltip: '放大',
                      child: const Icon(Icons.zoom_in, size: 20),
                    ),
                    const SizedBox(height: 8),
                    // 缩小按钮
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'zoom_out',
                      onPressed: _zoomOut,
                      tooltip: '缩小',
                      child: const Icon(Icons.zoom_out, size: 20),
                    ),
                    const SizedBox(height: 8),
                    // 切换旗子显示按钮
                    FloatingActionButton(
                      key: const Key('toggle_flags_button'),
                      mini: true,
                      heroTag: 'toggle_flags',
                      onPressed: () {
                        setState(() {
                          _areFlagsVisible = !_areFlagsVisible;
                        });
                      },
                      tooltip: _areFlagsVisible ? '隐藏旗子' : '显示旗子',
                      child: Icon(
                        _areFlagsVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // 用户颜色图例
        if (flags.isNotEmpty) UserColorLegend(flags: flags),

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
                  onPurchaseStatusChange: (flag, status) =>
                      _updatePurchaseStatus(flag, status),
                  onFinalStatusChange: (flag, status) =>
                      _updateFinalStatus(flag, status),
                  onDelete: (flag) => _deleteFlag(flag),
                  // TODO: 暂时移除转换价格功能
                  // onConvertedPriceTap: () => context.push('/formula'),
                ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(Photo? photo, List<Flag> flags) {
    final l10n = AppLocalizations.of(context)!;
    final userData = ref.watch(currentUserDataProvider);
    final teamId = userData.value?.teamId;

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
              // 左上角：谁在看这张照片
              if (teamId != null)
                Positioned(
                  top: 16,
                  left: 16,
                  child: ScreenActivityIndicator(
                    teamId: teamId,
                    screen: 'photo_detail',
                    context: {'photo_id': widget.photoId},
                  ),
                ),
              // 右上角按钮组
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    // 重置视图按钮
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'reset_desktop_view',
                      onPressed: () {
                        _transformationController.value = Matrix4.identity();
                      },
                      tooltip: l10n.resetView,
                      child: const Icon(Icons.refresh, size: 20),
                    ),
                    const SizedBox(height: 8),
                    // 切换旗子显示按钮
                    FloatingActionButton(
                      key: const Key('toggle_flags_button'),
                      mini: true,
                      heroTag: 'toggle_flags_desktop',
                      onPressed: () {
                        setState(() {
                          _areFlagsVisible = !_areFlagsVisible;
                        });
                      },
                      tooltip: _areFlagsVisible ? '隐藏旗子' : '显示旗子',
                      child: Icon(
                        _areFlagsVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const VerticalDivider(width: 1),

        // 右侧：Flag表格
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // 用户颜色图例
              if (flags.isNotEmpty) UserColorLegend(flags: flags),
              // Flag表格
              Expanded(
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
                        onPriceUpdate: (flag, price) =>
                            _updateFlagPrice(flag, price),
                        onTargetPriceUpdate: (flag, targetPrice) =>
                            _updateFlagTargetPrice(flag, targetPrice),
                        onPurchaseStatusChange: (flag, status) =>
                            _updatePurchaseStatus(flag, status),
                        onDelete: (flag) => _deleteFlag(flag),
                        // TODO: 暂时移除转换价格功能
                        // onConvertedPriceTap: () => context.push('/formula'),
                      ),
              ),
            ],
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

/// 旗子连线绘制器，用于显示重叠旗子展开后的连线
class _FlagConnectorPainter extends CustomPainter {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final Color color;

  _FlagConnectorPainter({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(startX, startY),
      Offset(startX + endX, startY + endY),
      paint,
    );
  }

  @override
  bool shouldRepaint(_FlagConnectorPainter oldDelegate) {
    return oldDelegate.startX != startX ||
        oldDelegate.startY != startY ||
        oldDelegate.endX != endX ||
        oldDelegate.endY != endY ||
        oldDelegate.color != color;
  }
}
