import 'package:flutter/material.dart';
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
  XFile? _selectedCoverImage;

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
      final boothService = ref.read(boothServiceProvider);
      final coverUrl = await boothService.uploadBoothCover(
        imageFile: coverImage,
        boothId: boothId,
        teamId: teamId,
      );

      // 更新摊位封面URL
      await boothService.updateBooth(
        boothId: boothId,
        coverImageUrl: coverUrl,
      );

      if (mounted) {
        // 刷新列表以显示封面
        ref.invalidate(boothsProvider);
      }
    } catch (e) {
      // 封面上传失败不影响摊位创建
      print('[_uploadBoothCoverInBackground] Failed to upload cover: $e');
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.edit),
        content: Form(
          key: formKey,
          child: TextFormField(
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
                _editBooth(booth, numberController.text);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _editBooth(Booth booth, String newBoothNumber) async {
    final l10n = AppLocalizations.of(context)!;
    if (newBoothNumber == booth.boothNumber) {
      return; // 没有变化，不需要更新
    }

    try {
      final boothService = ref.read(boothServiceProvider);
      await boothService.updateBooth(
        boothId: booth.id,
        boothNumber: newBoothNumber,
      );

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

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
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
    final l10n = AppLocalizations.of(context)!;
    final photosAsync = ref.watch(photosProvider(booth.id));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 封面图片区域
            Expanded(
              flex: 3,
              child: booth.coverImageUrl != null
                  ? Image.network(
                      booth.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _DefaultBoothImage();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
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
            // 信息区域
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.boothLabel(booth.boothNumber),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    photosAsync.when(
                      data: (photos) => Row(
                        children: [
                          Icon(Icons.photo_library,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            l10n.photoCountLabel(photos.length),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      loading: () => Text(
                        l10n.loading,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      error: (_, __) => Text(
                        l10n.photoCountLabel(0),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
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
  }
}

/// 默认摊位图片（无封面时显示）
class _DefaultBoothImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.shade50,
      child: Center(
        child: Icon(
          Icons.store,
          size: 48,
          color: Colors.blue.shade200,
        ),
      ),
    );
  }
}
