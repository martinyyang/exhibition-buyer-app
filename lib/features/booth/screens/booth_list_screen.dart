import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/booth.dart';
import '../providers/booth_provider.dart';
import '../../event/providers/event_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/safe_back_button.dart';
import '../../photo/providers/photo_provider.dart';

class BoothListScreen extends ConsumerStatefulWidget {
  final String eventId;

  const BoothListScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<BoothListScreen> createState() => _BoothListScreenState();
}

class _BoothListScreenState extends ConsumerState<BoothListScreen> {
  bool _isCreating = false;

  void _showCreateBoothDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final authService = ref.read(authServiceProvider);

    // 获取团队信息生成默认编号
    String? teamId;
    String? userId;
    for (int i = 0; i < 3; i++) {
      final user = await authService.getCurrentUser();
      teamId = user?.teamId;
      userId = user?.id;
      if (teamId != null && userId != null) break;
      if (i < 2) await Future.delayed(const Duration(seconds: 1));
    }

    if (teamId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.userNotInTeam)),
        );
      }
      return;
    }

    // 生成下一个编号
    final boothService = ref.read(boothServiceProvider);
    final defaultNumber = await boothService.generateNextBoothNumber(
      eventId: widget.eventId,
      teamId: teamId,
    );

    if (!mounted) return;

    final numberController = TextEditingController(text: defaultNumber);
    final formKey = GlobalKey<FormState>();
    XFile? dialogCoverImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.createNewBooth),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: numberController,
                  decoration: InputDecoration(
                    labelText: l10n.boothNumber,
                    hintText: l10n.boothNumberHint,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.boothNumberRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (dialogCoverImage != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          dialogCoverImage!.path,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 100,
                            width: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setDialogState(() {
                              dialogCoverImage = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1920,
                      maxHeight: 1920,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      setDialogState(() {
                        dialogCoverImage = image;
                      });
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: Text(dialogCoverImage == null ? '拍摄封面（可选）' : '重新拍摄'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  _createBooth(numberController.text, dialogCoverImage);
                }
              },
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBooth(String boothNumber, XFile? coverImage) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isCreating = true;
    });

    try {
      final authService = ref.read(authServiceProvider);

      // 获取用户信息和team_id（带重试逻辑）
      String? teamId;
      String? userId;
      for (int i = 0; i < 3; i++) {
        final user = await authService.getCurrentUser();
        teamId = user?.teamId;
        userId = user?.id;

        if (teamId != null && userId != null) break;

        if (i < 2) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (teamId == null || userId == null) {
        throw Exception(l10n.userNotInTeam);
      }

      final boothService = ref.read(boothServiceProvider);

      // 立即创建摊位记录（不等待封面上传）
      final booth = await boothService.createBooth(
        boothNumber: boothNumber,
        eventId: widget.eventId,
        teamId: teamId,
        createdBy: userId,
      );

      if (mounted) {
        // 手动刷新摊位列表
        ref.invalidate(boothsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.boothCreatedSuccess(boothNumber))),
        );
      }

      // 后台异步上传封面图片（不阻塞用户）
      if (coverImage != null) {
        _uploadBoothCoverInBackground(booth.id, teamId, coverImage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.createFailed(e.toString())),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  /// 后台上传封面图片
  Future<void> _uploadBoothCoverInBackground(
    String boothId,
    String teamId,
    XFile coverImage,
  ) async {
    try {
      debugPrint(
          '[_uploadBoothCoverInBackground] Starting upload for booth: $boothId');
      final boothService = ref.read(boothServiceProvider);

      final coverUrl = await boothService.uploadBoothCover(
        imageFile: coverImage,
        boothId: boothId,
        teamId: teamId,
      );
      debugPrint(
          '[_uploadBoothCoverInBackground] Upload successful, URL: $coverUrl');

      // 更新摊位封面URL
      final updatedBooth = await boothService.updateBooth(
        boothId: boothId,
        coverImageUrl: coverUrl,
      );
      debugPrint(
          '[_uploadBoothCoverInBackground] Database updated, new coverImageUrl: ${updatedBooth.coverImageUrl}');

      if (mounted) {
        // 刷新列表以显示封面
        ref.invalidate(boothsProvider);
        debugPrint('[_uploadBoothCoverInBackground] Provider invalidated');
      }
    } catch (e, stackTrace) {
      // 封面上传失败不影响摊位创建
      debugPrint('[_uploadBoothCoverInBackground] Failed to upload cover: $e');
      debugPrint('[_uploadBoothCoverInBackground] Stack trace: $stackTrace');
    }
  }

  void _onBoothTap(Booth booth) {
    // 导航到照片网格页面
    context.go('/events/${widget.eventId}/booths/${booth.id}/photos');
  }

  void _onBoothLongPress(Booth booth) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(l10n.edit),
            onTap: () {
              Navigator.pop(context);
              _showEditBoothDialog(booth);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteBooth(booth);
            },
          ),
        ],
      ),
    );
  }

  void _showEditBoothDialog(Booth booth) {
    final l10n = AppLocalizations.of(context)!;
    final numberController = TextEditingController(text: booth.boothNumber);
    final formKey = GlobalKey<FormState>();
    XFile? newCoverImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.edit),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: numberController,
                  decoration: InputDecoration(
                    labelText: l10n.boothNumber,
                    hintText: l10n.boothNumberHint,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.boothNumberRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // 封面预览和更换按钮
                if (booth.coverImageUrl != null || newCoverImage != null)
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: newCoverImage != null
                        ? FutureBuilder<Uint8List>(
                            future: newCoverImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              booth.coverImageUrl!,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.camera,
                      preferredCameraDevice: CameraDevice.rear,
                    );
                    if (image != null) {
                      setState(() {
                        newCoverImage = image;
                      });
                    }
                  },
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: Text(booth.coverImageUrl != null
                      ? l10n.changeCover
                      : l10n.addCover),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  _editBooth(booth, numberController.text, newCoverImage);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editBooth(
      Booth booth, String newBoothNumber, XFile? newCoverImage) async {
    final l10n = AppLocalizations.of(context)!;
    final hasNumberChanged = newBoothNumber != booth.boothNumber;

    if (!hasNumberChanged && newCoverImage == null) {
      return; // 没有变化，不需要更新
    }

    try {
      final boothService = ref.read(boothServiceProvider);

      // 更新摊位编号
      if (hasNumberChanged) {
        await boothService.updateBooth(
          boothId: booth.id,
          boothNumber: newBoothNumber,
        );
      }

      // 更新封面图片
      if (newCoverImage != null) {
        final authService = ref.read(authServiceProvider);
        final user = await authService.getCurrentUser();
        final teamId = user?.teamId;

        if (teamId != null) {
          // 等待封面上传完成（编辑场景需要立即看到结果）
          await _uploadBoothCoverInBackground(booth.id, teamId, newCoverImage);
        }
      }

      if (mounted) {
        // 手动刷新摊位列表
        ref.invalidate(boothsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.supplierInfoUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.uploadFailed(e.toString())),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _confirmDeleteBooth(Booth booth) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteBoothMessage(booth.boothNumber)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBooth(booth);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBooth(Booth booth) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final boothService = ref.read(boothServiceProvider);
      await boothService.deleteBooth(booth.id);

      if (mounted) {
        // 手动刷新摊位列表
        ref.invalidate(boothsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.boothDeletedSuccess(booth.boothNumber))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.deleteFailed(e.toString())),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 获取当前用户的team_id
    final authService = ref.watch(authServiceProvider);
    final userId = authService.currentUserId;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.boothListTitle)),
        body: Center(child: Text(l10n.loginTitle)),
      );
    }

    // 获取场次信息
    final eventAsync = ref.watch(eventProvider(widget.eventId));

    return eventAsync.when(
      data: (event) {
        if (event == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.boothListTitle)),
            body: Center(child: Text(l10n.noEvents)),
          );
        }

        // 获取摊位列表
        final boothsParams = BoothsParams(
          eventId: widget.eventId,
          teamId: event.teamId,
        );
        final boothsAsync = ref.watch(boothsProvider(boothsParams));

        return Scaffold(
          appBar: AppBar(
            leading: const SafeBackButton(fallbackPath: '/events'),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.boothListTitle, style: const TextStyle(fontSize: 16)),
                Text(
                  event.name,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _isCreating ? null : _showCreateBoothDialog,
                tooltip: l10n.createNewBooth,
              ),
            ],
          ),
          body: boothsAsync.when(
            data: (booths) {
              if (booths.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.store,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noBooths,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.createFirstBooth,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  // 响应式列数：移动端3列，平板4列，桌面5列
                  int crossAxisCount;
                  if (constraints.maxWidth < 600) {
                    crossAxisCount = 3; // 手机
                  } else if (constraints.maxWidth < 900) {
                    crossAxisCount = 4; // 平板
                  } else {
                    crossAxisCount = 5; // 桌面
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: booths.length,
                    itemBuilder: (context, index) {
                      final booth = booths[index];
                      return _BoothCard(
                        booth: booth,
                        onTap: () => _onBoothTap(booth),
                        onLongPress: () => _onBoothLongPress(booth),
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: LoadingIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(l10n.loadFailed(error.toString())),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(boothsProvider),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(l10n.boothListTitle),
          leading: const SafeBackButton(fallbackPath: '/events'),
        ),
        body: const Center(child: LoadingIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.boothListTitle),
          leading: const SafeBackButton(fallbackPath: '/events'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(l10n.loadFailed(error.toString())),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(eventProvider(widget.eventId)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 摊位卡片组件 - 网格布局
class _BoothCard extends ConsumerWidget {
  final Booth booth;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BoothCard({
    required this.booth,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photosProvider(booth.id));

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 封面图片区域（正方形）
            AspectRatio(
              aspectRatio: 1.0,
              child: booth.coverImageUrl != null
                  ? Image.network(
                      booth.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint(
                            '[BoothCard] Failed to load image for booth ${booth.boothNumber}');
                        debugPrint('[BoothCard] URL: ${booth.coverImageUrl}');
                        debugPrint('[BoothCard] Error: $error');
                        return _DefaultBoothImage();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          debugPrint(
                              '[BoothCard] Image loaded successfully for booth ${booth.boothNumber}');
                          return child;
                        }
                        debugPrint(
                            '[BoothCard] Loading image for booth ${booth.boothNumber}: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes ?? "unknown"}');
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    )
                  : _DefaultBoothImage(),
            ),
            // 信息区域（紧凑）
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booth.boothNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  photosAsync.when(
                    data: (photos) => Row(
                      children: [
                        Icon(Icons.photo_library,
                            size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 3),
                        Text(
                          '${photos.length}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    loading: () => Text(
                      '...',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    error: (_, __) => Text(
                      '0',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  // DEBUG: 显示封面URL
                  if (booth.coverImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'URL: ${booth.coverImageUrl!.substring(0, booth.coverImageUrl!.length > 40 ? 40 : booth.coverImageUrl!.length)}...',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.red[600],
                          fontFamily: 'monospace',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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

/// 默认摊位图片（无封面时显示）
class _DefaultBoothImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          Icons.store,
          size: 36,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
