import 'package:flutter/material.dart';
import '../../../shared/widgets/warning_badge.dart';
import '../models/flag.dart';

class FlagTable extends StatefulWidget {
  final List<Flag> flags;
  final bool isRemoteView;
  final Function(Flag)? onRowTap;
  final Function(Flag, double)? onPriceUpdate;
  final Function(Flag, double)? onTargetPriceUpdate;

  const FlagTable({
    super.key,
    required this.flags,
    required this.isRemoteView,
    this.onRowTap,
    this.onPriceUpdate,
    this.onTargetPriceUpdate,
  });

  @override
  State<FlagTable> createState() => _FlagTableState();
}

class _FlagTableState extends State<FlagTable> {
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _targetPriceControllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(FlagTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flags != widget.flags) {
      _initControllers();
    }
  }

  void _initControllers() {
    // 清理旧的控制器
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    for (var controller in _targetPriceControllers.values) {
      controller.dispose();
    }
    _priceControllers.clear();
    _targetPriceControllers.clear();

    // 初始化新的控制器
    for (var flag in widget.flags) {
      _priceControllers[flag.id] = TextEditingController(
        text: flag.priceRmb?.toString() ?? '',
      );
      _targetPriceControllers[flag.id] = TextEditingController(
        text: flag.targetPrice?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    for (var controller in _targetPriceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
          columns: [
            const DataColumn(label: Text('编号')),
            if (!widget.isRemoteView)
              const DataColumn(label: Text('报价(¥)')),
            if (widget.isRemoteView)
              const DataColumn(label: Text('卖家报价')),
            const DataColumn(label: Text('换算价')),
            if (widget.isRemoteView)
              const DataColumn(label: Text('目标价')),
            const DataColumn(label: Text('状态')),
          ],
          rows: widget.flags.map((flag) {
            return DataRow(
              onSelectChanged: (_) {
                if (widget.onRowTap != null) {
                  widget.onRowTap!(flag);
                }
              },
              cells: [
                // 编号列
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                    ],
                  ),
                ),

                // 报价列（买手端可编辑，远程端只读）
                if (!widget.isRemoteView)
                  DataCell(
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _priceControllers[flag.id],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '输入报价',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (value) {
                          final price = double.tryParse(value);
                          if (price != null && widget.onPriceUpdate != null) {
                            widget.onPriceUpdate!(flag, price);
                          }
                        },
                      ),
                    ),
                  ),

                if (widget.isRemoteView)
                  DataCell(
                    Text(
                      flag.priceRmb != null ? '¥${flag.priceRmb}' : '-',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                // 换算价列（只读）
                DataCell(
                  Text(
                    flag.priceConverted != null
                        ? flag.priceConverted!.toStringAsFixed(2)
                        : '-',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),

                // 目标价列（远程端可编辑）
                if (widget.isRemoteView)
                  DataCell(
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _targetPriceControllers[flag.id],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '目标价',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (value) {
                          final targetPrice = double.tryParse(value);
                          if (targetPrice != null &&
                              widget.onTargetPriceUpdate != null) {
                            widget.onTargetPriceUpdate!(flag, targetPrice);
                          }
                        },
                      ),
                    ),
                  ),

                // 状态列
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (flag.needsAttention)
                        const WarningBadge(show: true)
                      else if (flag.priceRmb != null &&
                          flag.targetPrice != null)
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        )
                      else
                        Icon(
                          Icons.pending,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
