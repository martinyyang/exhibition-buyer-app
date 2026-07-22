import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive.dart';
import '../../photo/models/photo.dart';
import '../../flag/models/flag.dart';
import '../../flag/widgets/flag_table.dart';
import '../../photo/widgets/photo_annotation_canvas.dart';

/// Web端Dashboard布局
/// 左侧：买手列表 + 在线状态
/// 中间：照片大图 + 标注工具
/// 右侧：Flag表格（可直接编辑）
class WebDashboardLayout extends ConsumerStatefulWidget {
  final Photo photo;
  final List<Flag> flags;
  final Function(Offset) onAddFlag;
  final Function(Flag) onUpdateFlag;

  const WebDashboardLayout({
    super.key,
    required this.photo,
    required this.flags,
    required this.onAddFlag,
    required this.onUpdateFlag,
  });

  @override
  ConsumerState<WebDashboardLayout> createState() => _WebDashboardLayoutState();
}

class _WebDashboardLayoutState extends ConsumerState<WebDashboardLayout> {
  Flag? _selectedFlag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('远程审核 - Web端'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: 打开设置页面
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // 左侧：买手列表
          _buildBuyerSidebar(),

          // 中间：照片标注区域
          Expanded(
            flex: 3,
            child: _buildPhotoSection(),
          ),

          // 右侧：Flag表格
          _buildFlagSidebar(),
        ],
      ),
    );
  }

  /// 左侧买手列表
  Widget _buildBuyerSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          right: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.people),
                const SizedBox(width: 8),
                Text(
                  '买手列表',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildBuyerItem('买手A', '🟢', isOnline: true, photoCount: 15),
                _buildBuyerItem('买手B', '🔵', isOnline: true, photoCount: 12),
                _buildBuyerItem('买手C', '🟡', isOnline: false, photoCount: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 买手列表项
  Widget _buildBuyerItem(
    String name,
    String colorEmoji,
    {
    required bool isOnline,
    required int photoCount,
  }) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            child: Text(colorEmoji),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(name),
      subtitle: Text('$photoCount 张照片'),
      trailing: isOnline
          ? const Icon(Icons.circle, color: Colors.green, size: 12)
          : const Icon(Icons.circle, color: Colors.grey, size: 12),
    );
  }

  /// 中间照片标注区域
  Widget _buildPhotoSection() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        children: [
          // 工具栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '摊位号: ${widget.photo.boothId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                if (widget.photo.supplierName != null) ...[
                  const Icon(Icons.store, size: 16),
                  const SizedBox(width: 4),
                  Text(widget.photo.supplierName!),
                ],
                const Spacer(),
                Text('${widget.flags.length} 个标注'),
              ],
            ),
          ),

          // 照片标注画布
          Expanded(
            child: Center(
              child: PhotoAnnotationCanvas(
                photoUrl: widget.photo.url,
                flags: widget.flags,
                onAddFlag: widget.onAddFlag,
                selectedFlagId: _selectedFlag?.id,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 右侧Flag表格
  Widget _buildFlagSidebar() {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.flag),
                const SizedBox(width: 8),
                Text(
                  '标注详情',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // 刷新数据
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FlagTable(
              flags: widget.flags,
              isRemoteView: true,
              onEdit: (flag) {
                setState(() {
                  _selectedFlag = flag;
                });
              },
              onRowTap: (flag) {
                // 点击行时聚焦到对应旗子
                setState(() {
                  _selectedFlag = flag;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
