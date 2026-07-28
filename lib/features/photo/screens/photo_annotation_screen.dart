import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../flag/models/flag.dart';
import '../../flag/providers/flag_provider.dart';
import '../../flag/services/flag_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/photo_annotation_canvas.dart';
import '../models/photo.dart';
import '../providers/photo_provider.dart';

class PhotoAnnotationScreen extends ConsumerStatefulWidget {
  final String photoId;

  const PhotoAnnotationScreen({
    super.key,
    required this.photoId,
  });

  @override
  ConsumerState<PhotoAnnotationScreen> createState() =>
      _PhotoAnnotationScreenState();
}

class _PhotoAnnotationScreenState extends ConsumerState<PhotoAnnotationScreen> {
  Flag? _selectedFlag;
  bool _isAddingFlag = false;

  @override
  Widget build(BuildContext context) {
    final photoAsync = ref.watch(photoProvider(widget.photoId));
    final flagsAsync = ref.watch(flagsProvider(widget.photoId));
    final currentUser = ref.watch(currentUserDataProvider);
    final userId = currentUser.value?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('照片标注'),
        actions: [
          IconButton(
            icon: Icon(_isAddingFlag ? Icons.check : Icons.add_location),
            onPressed: () {
              setState(() {
                _isAddingFlag = !_isAddingFlag;
                if (!_isAddingFlag) {
                  _selectedFlag = null;
                }
              });
            },
            tooltip: _isAddingFlag ? '完成标注' : '添加标记',
          ),
          if (_selectedFlag != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteFlag(_selectedFlag!),
              tooltip: '删除标记',
            ),
        ],
      ),
      body: photoAsync.when(
        data: (photo) {
          if (photo == null) {
            return const Center(child: Text('照片不存在'));
          }

          return flagsAsync.when(
            data: (flags) => Column(
              children: [
                // 提示信息
                if (_isAddingFlag)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.blue.withOpacity(0.1),
                    child: const Text(
                      '点击照片任意位置添加标记',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // 照片标注区域
                Expanded(
                  child: PhotoAnnotationCanvas(
                    imageUrl: photo.url,
                    flags: flags,
                    onTap: _isAddingFlag && userId != null
                        ? (offset) => _addFlag(offset, flags.length + 1, userId)
                        : null,
                    onFlagLongPress: (flag) {
                      setState(() {
                        _selectedFlag = flag;
                      });
                      _showFlagDetails(flag);
                    },
                    enableZoom: true,
                  ),
                ),

                // 底部标记列表
                if (flags.isNotEmpty)
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(8),
                      itemCount: flags.length,
                      itemBuilder: (context, index) {
                        final flag = flags[index];
                        return _buildFlagCard(flag);
                      },
                    ),
                  ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('加载失败: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加载失败: $err')),
      ),
    );
  }

  Widget _buildFlagCard(Flag flag) {
    final isSelected = _selectedFlag?.id == flag.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFlag = isSelected ? null : flag;
        });
      },
      onLongPress: () => _showFlagDetails(flag),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.white,
          border: Border.all(
            color: flag.needsAttention
                ? Colors.red
                : (isSelected ? Colors.blue : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: flag.needsAttention ? Colors.red : Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${flag.number}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (flag.priceRmb != null)
              Text(
                '¥${flag.priceRmb!.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFlag(Offset position, int number, String userId) async {
    try {
      final flagService = ref.read(flagServiceProvider);
      await flagService.createFlag(
        photoId: widget.photoId,
        positionX: position.dx,
        positionY: position.dy,
        createdBy: userId,
      );

      // 刷新标记列表
      ref.invalidate(flagsProvider(widget.photoId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已添加标记')),
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

  Future<void> _deleteFlag(Flag flag) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除标记'),
        content: Text('确定要删除标记 #${flag.number} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final flagService = ref.read(flagServiceProvider);
      await flagService.deleteFlag(flag.id);

      // 刷新标记列表
      ref.invalidate(flagsProvider(widget.photoId));

      setState(() {
        _selectedFlag = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('标记已删除')),
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

  void _showFlagDetails(Flag flag) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FlagDetailsSheet(
        flag: flag,
        photoId: widget.photoId,
      ),
    );
  }
}

class _FlagDetailsSheet extends ConsumerStatefulWidget {
  final Flag flag;
  final String photoId;

  const _FlagDetailsSheet({
    required this.flag,
    required this.photoId,
  });

  @override
  ConsumerState<_FlagDetailsSheet> createState() => _FlagDetailsSheetState();
}

class _FlagDetailsSheetState extends ConsumerState<_FlagDetailsSheet> {
  late TextEditingController _priceRmbController;
  late TextEditingController _targetPriceController;
  bool _needsAttention = false;

  @override
  void initState() {
    super.initState();
    _priceRmbController = TextEditingController(
      text: widget.flag.priceRmb?.toStringAsFixed(0) ?? '',
    );
    _targetPriceController = TextEditingController(
      text: widget.flag.targetPrice?.toStringAsFixed(2) ?? '',
    );
    _needsAttention = widget.flag.needsAttention;
  }

  @override
  void dispose() {
    _priceRmbController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _needsAttention ? Colors.red : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${widget.flag.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '标记 #${widget.flag.number}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _priceRmbController,
            decoration: const InputDecoration(
              labelText: '人民币价格',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _targetPriceController,
            decoration: const InputDecoration(
              labelText: '目标价格',
              prefixText: '\$',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('需要注意'),
            subtitle: const Text('标记为需要特别关注的商品'),
            value: _needsAttention,
            onChanged: (value) {
              setState(() {
                _needsAttention = value;
              });
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    try {
      final flagService = ref.read(flagServiceProvider);

      double? priceRmb;
      if (_priceRmbController.text.isNotEmpty) {
        priceRmb = double.tryParse(_priceRmbController.text);
      }

      double? targetPrice;
      if (_targetPriceController.text.isNotEmpty) {
        targetPrice = double.tryParse(_targetPriceController.text);
      }

      await flagService.updateFlag(
        flagId: widget.flag.id,
        priceRmb: priceRmb,
        targetPrice: targetPrice,
        needsAttention: _needsAttention,
      );

      // 刷新标记列表
      ref.invalidate(flagsProvider(widget.photoId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }
}
