import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/flag.dart';
import '../../../core/utils/debouncer.dart';

class FlagTable extends StatefulWidget {
  final List<Flag> flags;
  final bool isRemoteView;
  final Function(Flag)? onRowTap;
  final Function(Flag, double)? onPriceUpdate;
  final Function(Flag, double)? onTargetPriceUpdate;
  final Function(Flag, bool)? onPurchaseToggle;
  final Function(Flag)? onDelete;
  final VoidCallback? onConvertedPriceTap;

  const FlagTable({
    super.key,
    required this.flags,
    required this.isRemoteView,
    this.onRowTap,
    this.onPriceUpdate,
    this.onTargetPriceUpdate,
    this.onPurchaseToggle,
    this.onDelete,
    this.onConvertedPriceTap,
  });

  @override
  State<FlagTable> createState() => _FlagTableState();
}

class _FlagTableState extends State<FlagTable> {
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _targetPriceControllers = {};
  final Debouncer _priceDebouncer =
      Debouncer(delay: Duration(milliseconds: 800));
  final Debouncer _targetPriceDebouncer =
      Debouncer(delay: Duration(milliseconds: 800));

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(FlagTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flags != widget.flags) {
      _updateControllersIfNeeded();
    }
  }

  void _updateControllersIfNeeded() {
    // 只更新发生变化的controller，避免重置正在编辑的输入框
    for (var flag in widget.flags) {
      // 如果是新flag，创建controller
      if (!_priceControllers.containsKey(flag.id)) {
        _priceControllers[flag.id] = TextEditingController(
          text: flag.priceRmb?.toString() ?? '',
        );
      } else {
        // 只在值真正改变且不是当前焦点时更新
        final controller = _priceControllers[flag.id]!;
        final newValue = flag.priceRmb?.toString() ?? '';
        if (controller.text != newValue && !controller.selection.isValid) {
          controller.text = newValue;
        }
      }

      if (!_targetPriceControllers.containsKey(flag.id)) {
        _targetPriceControllers[flag.id] = TextEditingController(
          text: flag.targetPrice?.toString() ?? '',
        );
      } else {
        final controller = _targetPriceControllers[flag.id]!;
        final newValue = flag.targetPrice?.toString() ?? '';
        if (controller.text != newValue && !controller.selection.isValid) {
          controller.text = newValue;
        }
      }
    }

    // 清理已删除flag的controller
    _priceControllers.removeWhere((id, controller) {
      final exists = widget.flags.any((f) => f.id == id);
      if (!exists) controller.dispose();
      return !exists;
    });
    _targetPriceControllers.removeWhere((id, controller) {
      final exists = widget.flags.any((f) => f.id == id);
      if (!exists) controller.dispose();
      return !exists;
    });
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
    _priceDebouncer.dispose();
    _targetPriceDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 检测屏幕宽度判断是否为移动端
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: isMobile ? 32 : 56,
          dataRowHeight: isMobile ? 40 : 56,
          headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
          columnSpacing: isMobile ? 12 : 32,
          horizontalMargin: isMobile ? 8 : 16,
          columns: [
            DataColumn(
              label: Text(
                l10n.number,
                style: TextStyle(fontSize: isMobile ? 12 : 14),
              ),
            ),
            if (!widget.isRemoteView)
              DataColumn(
                label: Text(
                  l10n.priceRmb,
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
              ),
            if (widget.isRemoteView)
              DataColumn(
                label: Text(
                  l10n.sellerPrice,
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
              ),
            DataColumn(
              label: Text(
                l10n.convertedPrice,
                style: TextStyle(fontSize: isMobile ? 12 : 14),
              ),
            ),
            if (widget.isRemoteView)
              DataColumn(
                label: Text(
                  l10n.targetPrice,
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
              ),
            DataColumn(
              label: Text(
                l10n.purchased,
                style: TextStyle(fontSize: isMobile ? 12 : 14),
              ),
            ),
            DataColumn(
              label: Text(
                l10n.delete,
                style: TextStyle(fontSize: isMobile ? 12 : 14),
              ),
            ),
          ],
          rows: widget.flags.map((flag) {
            return DataRow(
              cells: [
                // 编号列
                DataCell(
                  InkWell(
                    onTap: () {
                      if (widget.onRowTap != null) {
                        widget.onRowTap!(flag);
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isMobile ? 24 : 32,
                          height: isMobile ? 24 : 32,
                          decoration: BoxDecoration(
                            color:
                                flag.needsAttention ? Colors.red : Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${flag.number}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 11 : 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 报价列（所有人都可以编辑）
                if (!widget.isRemoteView)
                  DataCell(
                    SizedBox(
                      width: isMobile ? 70 : 100,
                      child: TextField(
                        controller: _priceControllers[flag.id],
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                        decoration: InputDecoration(
                          hintText: l10n.enterPrice,
                          hintStyle: TextStyle(fontSize: isMobile ? 11 : 14),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 4 : 8,
                            vertical: isMobile ? 4 : 8,
                          ),
                        ),
                        onChanged: (value) {
                          _priceDebouncer.run(() {
                            final price = double.tryParse(value);
                            if (price != null && widget.onPriceUpdate != null) {
                              widget.onPriceUpdate!(flag, price);
                            }
                          });
                        },
                      ),
                    ),
                  ),

                // 远程端：卖家报价可编辑
                if (widget.isRemoteView)
                  DataCell(
                    SizedBox(
                      width: isMobile ? 70 : 100,
                      child: TextField(
                        controller: _priceControllers[flag.id],
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                        decoration: InputDecoration(
                          hintText: l10n.enterPrice,
                          hintStyle: TextStyle(fontSize: isMobile ? 11 : 14),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 4 : 8,
                            vertical: isMobile ? 4 : 8,
                          ),
                        ),
                        onChanged: (value) {
                          _priceDebouncer.run(() {
                            final price = double.tryParse(value);
                            if (price != null && widget.onPriceUpdate != null) {
                              widget.onPriceUpdate!(flag, price);
                            }
                          });
                        },
                      ),
                    ),
                  ),

                // 换算价列（点击跳转到公式设置）
                DataCell(
                  InkWell(
                    onTap: widget.onConvertedPriceTap,
                    child: Text(
                      flag.priceConverted != null
                          ? flag.priceConverted!.toStringAsFixed(2)
                          : '-',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: flag.priceConverted == null
                            ? Colors.blue
                            : Colors.grey[700],
                        decoration: flag.priceConverted == null
                            ? TextDecoration.underline
                            : null,
                      ),
                    ),
                  ),
                ),

                // 目标价列（远程端可编辑）
                if (widget.isRemoteView)
                  DataCell(
                    SizedBox(
                      width: isMobile ? 70 : 100,
                      child: TextField(
                        controller: _targetPriceControllers[flag.id],
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                        decoration: InputDecoration(
                          hintText: l10n.targetPrice,
                          hintStyle: TextStyle(fontSize: isMobile ? 11 : 14),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 4 : 8,
                            vertical: isMobile ? 4 : 8,
                          ),
                        ),
                        onChanged: (value) {
                          _targetPriceDebouncer.run(() {
                            final targetPrice = double.tryParse(value);
                            if (targetPrice != null &&
                                widget.onTargetPriceUpdate != null) {
                              widget.onTargetPriceUpdate!(flag, targetPrice);
                            }
                          });
                        },
                      ),
                    ),
                  ),

                // 已购买复选框列
                DataCell(
                  Checkbox(
                    value: flag.isPurchased,
                    onChanged: widget.onPurchaseToggle != null
                        ? (value) {
                            if (value != null) {
                              widget.onPurchaseToggle!(flag, value);
                            }
                          }
                        : null,
                  ),
                ),

                // 删除按钮列
                DataCell(
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: isMobile ? 18 : 20,
                      color: Colors.red[300],
                    ),
                    onPressed: widget.onDelete != null
                        ? () => widget.onDelete!(flag)
                        : null,
                    tooltip: l10n.delete,
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
