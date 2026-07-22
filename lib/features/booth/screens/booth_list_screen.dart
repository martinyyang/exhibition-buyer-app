import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/color_badge.dart';
import '../models/booth.dart';

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
  bool _isLoading = false;
  String _eventName = '加载中...';
  final List<Booth> _booths = []; // TODO: 从Provider获取

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 加载场次信息和摊位列表
      // final eventService = ref.read(eventServiceProvider);
      // final event = await eventService.getEvent(widget.eventId);
      // final boothService = ref.read(boothServiceProvider);
      // final booths = await boothService.getBooths(widget.eventId);
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _eventName = '2026春季广交会'; // TODO: 从数据库获取
        });
      }
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
      _isLoading = true;
    });

    try {
      // TODO: 调用BoothService创建摊位
      // final boothService = ref.read(boothServiceProvider);
      // await boothService.createBooth(widget.eventId, boothNumber);
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('摊位 $boothNumber 创建成功')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
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

  void _onBoothTap(Booth booth) {
    // TODO: 导航到照片网格页面
    // context.go('/photos', extra: booth.id);
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
              // TODO: 编辑摊位
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
    // TODO: 调用BoothService删除摊位
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已删除摊位"${booth.boothNumber}"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('摊位列表', style: TextStyle(fontSize: 16)),
            Text(
              _eventName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateBoothDialog,
            tooltip: '新建摊位',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _booths.isEmpty
              ? Center(
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
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _booths.length,
                  itemBuilder: (context, index) {
                    final booth = _booths[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _onBoothTap(booth),
                        onLongPress: () => _onBoothLongPress(booth),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // TODO: 显示买手颜色标识
                              // ColorBadge(color: booth.createdByColor),
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
                                      '0张照片', // TODO: 显示实际照片数量
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
                ),
    );
  }
}
