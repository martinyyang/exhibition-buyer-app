import 'package:flutter/material.dart';
import '../services/formula_calculator.dart';

class FormulaInput extends StatefulWidget {
  final String? initialFormula;
  final List<String>? historyFormulas;
  final Function(String)? onSave;

  const FormulaInput({
    super.key,
    this.initialFormula,
    this.historyFormulas,
    this.onSave,
  });

  @override
  State<FormulaInput> createState() => _FormulaInputState();
}

class _FormulaInputState extends State<FormulaInput> {
  late TextEditingController _controller;
  String? _errorMessage;
  Map<double, double>? _previewResults;

  final List<double> _testPrices = [1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialFormula);
    _controller.addListener(_onFormulaChanged);
    if (widget.initialFormula != null && widget.initialFormula!.isNotEmpty) {
      _validateAndPreview();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onFormulaChanged() {
    _validateAndPreview();
  }

  void _validateAndPreview() {
    final formula = _controller.text.trim();

    if (formula.isEmpty) {
      setState(() {
        _errorMessage = null;
        _previewResults = null;
      });
      return;
    }

    // 验证公式
    if (!FormulaCalculator.validateFormula(formula)) {
      setState(() {
        _errorMessage = '公式错误，请检查';
        _previewResults = null;
      });
      return;
    }

    // 计算预览
    try {
      final results = FormulaCalculator.preview(formula, _testPrices);
      setState(() {
        _errorMessage = null;
        _previewResults = results;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '公式错误: $e';
        _previewResults = null;
      });
    }
  }

  void _onHistoryFormulaTap(String formula) {
    _controller.text = formula;
  }

  void _onSave() {
    final formula = _controller.text.trim();

    if (formula.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入公式')),
      );
      return;
    }

    if (!FormulaCalculator.validateFormula(formula)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('公式格式错误')),
      );
      return;
    }

    if (widget.onSave != null) {
      widget.onSave!(formula);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 公式输入框
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: '汇率公式',
            hintText: '例如：RMB * 0.14 或 (RMB - 50) * 0.14 + 10',
            errorText: _errorMessage,
            border: const OutlineInputBorder(),
            helperText: '使用 RMB 作为人民币价格变量',
          ),
          maxLines: 2,
        ),

        const SizedBox(height: 16),

        // 说明文字
        Text(
          '支持的运算：+ - * / ( )',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),

        const SizedBox(height: 16),

        // 预览结果
        if (_previewResults != null) ...[
          const Text(
            '预览计算结果',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: _previewResults!.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '¥${entry.key.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Icon(Icons.arrow_forward, size: 16),
                        Text(
                          entry.value.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 历史公式
        if (widget.historyFormulas != null &&
            widget.historyFormulas!.isNotEmpty) ...[
          const Text(
            '历史公式',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.historyFormulas!.map((formula) {
              return ActionChip(
                label: Text(
                  formula,
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () => _onHistoryFormulaTap(formula),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // 保存按钮
        if (widget.onSave != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onSave,
              child: const Text('保存'),
            ),
          ),
      ],
    );
  }
}
