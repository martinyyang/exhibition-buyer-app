import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/color_badge.dart';
import '../models/booth.dart';
import '../providers/booth_provider.dart';
import '../services/booth_service.dart';
import '../../event/providers/event_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/safe_back_button.dart';

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
    final numberController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建摊位'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: numberController,
            decoration: const InputDecoration(
              labelText: '摊位号',
              hintText: '例如：B01',
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入摊位号';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                _createBooth(numberController.text);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBooth(String boothNumber) async {
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
        throw Exception('用户未登录或未加入团队');
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
          SnackBar(content: Text('摊位 $boothNumber 创建成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建失败: $e'),
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
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('编辑'),
            onTap: () {
              Navigator.pop(context);
              _showEditBoothDialog(booth);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('删除', style: TextStyle(color: Colors.red)),
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
    final numberController = TextEditingController(text: booth.boothNumber);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑摊位'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: numberController,
            decoration: const InputDecoration(
              labelText: '摊位号',
              hintText: '例如：B01',
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入摊位号';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                _editBooth(booth, numberController.text);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _editBooth(Booth booth, String newBoothNumber) async {
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
          const SnackBar(content: Text('摊位信息已更新')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失败: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _confirmDeleteBooth(Booth booth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除摊位"${booth.boothNumber}"吗？\n所有照片和标注也会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBooth(booth);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBooth(Booth booth) async {
    try {
      final boothService = ref.read(boothServiceProvider);
      await boothService.deleteBooth(booth.id);

      if (mounted) {
        // 手动刷新摊位列表
        ref.invalidate(boothsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除摊位"${booth.boothNumber}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前用户的team_id
    final authService = ref.watch(authServiceProvider);
    final userId = authService.currentUserId;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('摊位列表')),
        body: const Center(child: Text('请先登录')),
      );
    }

    // 获取场次信息
    final eventAsync = ref.watch(eventProvider(widget.eventId));

    return eventAsync.when(
      data: (event) {
        if (event == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('摊位列表')),
            body: const Center(child: Text('场次不存在')),
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
                const Text('摊位列表', style: TextStyle(fontSize: 16)),
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
                tooltip: '新建摊位',
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
                        '暂无摊位',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '点击右上角+号创建第一个摊位',
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
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _onBoothTap(booth),
                      onLongPress: () => _onBoothLongPress(booth),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
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
                                    '摊位 ${booth.boothNumber}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '0张照片',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
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
                  Text('加载失败: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(boothsProvider),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('摊位列表'),
          leading: const SafeBackButton(fallbackPath: '/events'),
        ),
        body: const Center(child: LoadingIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('摊位列表'),
          leading: const SafeBackButton(fallbackPath: '/events'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(eventProvider(widget.eventId)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
