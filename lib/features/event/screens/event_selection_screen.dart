import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/event.dart';

class EventSelectionScreen extends ConsumerStatefulWidget {
  const EventSelectionScreen({super.key});

  @override
  ConsumerState<EventSelectionScreen> createState() =>
      _EventSelectionScreenState();
}

class _EventSelectionScreenState extends ConsumerState<EventSelectionScreen> {
  bool _isLoading = false;
  final List<Event> _events = []; // TODO: 从Provider获取

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 从EventService加载场次列表
      // final eventService = ref.read(eventServiceProvider);
      // final events = await eventService.getEvents();
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

  void _showCreateEventDialog() {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? startDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建新场次'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '场次名称',
                  hintText: '例如：2026春季广交会',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入场次名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('开始日期'),
                subtitle: Text(
                  startDate != null
                      ? '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}'
                      : '点击选择日期',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() {
                      startDate = date;
                    });
                  }
                },
              ),
            ],
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
                _createEvent(nameController.text, startDate);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  Future<void> _createEvent(String name, DateTime? startDate) async {
    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择开始日期')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 调用EventService创建场次
      // final eventService = ref.read(eventServiceProvider);
      // await eventService.createEvent(name, startDate);
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('场次创建成功')),
        );
        _loadEvents();
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

  void _onEventTap(Event event) {
    // TODO: 导航到摊位列表页面
    // context.go('/booths', extra: event.id);
  }

  void _onEventLongPress(Event event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!event.isActive)
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('设为活跃场次'),
              onTap: () {
                Navigator.pop(context);
                _setActiveEvent(event);
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('编辑'),
            onTap: () {
              Navigator.pop(context);
              // TODO: 编辑场次
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('删除', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteEvent(event);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _setActiveEvent(Event event) async {
    // TODO: 调用EventService设置活跃场次
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已将"${event.name}"设为活跃场次')),
    );
  }

  void _confirmDeleteEvent(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${event.name}"吗？\n此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent(event);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(Event event) async {
    // TODO: 调用EventService删除场次
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已删除"${event.name}"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择场次'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateEventDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无场次',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '点击右上角+号创建第一个场次',
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
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: event.isActive ? 4 : 1,
                      color: event.isActive
                          ? Colors.green.shade50
                          : null,
                      child: InkWell(
                        onTap: () => _onEventTap(event),
                        onLongPress: () => _onEventLongPress(event),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              if (event.isActive)
                                Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '当前',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${event.startDate.year}-${event.startDate.month.toString().padLeft(2, '0')}-${event.startDate.day.toString().padLeft(2, '0')}${event.endDate != null ? ' 至 ${event.endDate!.year}-${event.endDate!.month.toString().padLeft(2, '0')}-${event.endDate!.day.toString().padLeft(2, '0')}' : ''}',
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
