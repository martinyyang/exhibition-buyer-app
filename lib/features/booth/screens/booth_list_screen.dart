import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

  void _showCreateBoothDialog() {
    final l10n = AppLocalizations.of(context)!;
    final numberController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createNewBooth),
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
                _createBooth(numberController.text);
              }
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  Future<void> _createBooth(String boothNumber) async {
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
      await boothService.createBooth(
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

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: booths.length,
                itemBuilder: (context, index) {
                  final booth = booths[index];
                  return _BoothListItem(
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

/// 摊位列表项组件 - 显示照片缩略图
class _BoothListItem extends ConsumerWidget {
  final Booth booth;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BoothListItem({
    required this.booth,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final photosAsync = ref.watch(photosProvider(booth.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.store, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.boothLabel(booth.boothNumber),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        photosAsync.when(
                          data: (photos) => Text(
                            l10n.photoCountLabel(photos.length),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
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
                  const Icon(Icons.chevron_right),
                ],
              ),
              photosAsync.when(
                data: (photos) {
                  if (photos.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length > 5 ? 5 : photos.length,
                        itemBuilder: (context, index) {
                          final photo = photos[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                photo.url,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
