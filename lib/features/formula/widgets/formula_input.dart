import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/formula_calculator.dart';

class FormulaInput extends StatefulWidget {
  final String? initialFormula;
  final List<String>? historyFormulas;
  final Function(String)? onSave;
  final bool enabled;

  const FormulaInput({
    super.key,
    this.initialFormula,
    this.historyFormulas,
    this.onSave,
    this.enabled = true,
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
    final l10n = AppLocalizations.of(context)!;
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
        _errorMessage = l10n.formulaFormatError;
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
        _errorMessage = l10n.formulaCalculationError(e.toString());
        _previewResults = null;
      });
    }
  }

  void _onHistoryFormulaTap(String formula) {
    _controller.text = formula;
  }

  void _onSave() {
    final l10n = AppLocalizations.of(context)!;
    final formula = _controller.text.trim();

    if (formula.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterFormula)),
      );
      return;
    }

    if (!FormulaCalculator.validateFormula(formula)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.formulaFormatError)),
      );
      return;
    }

    if (widget.onSave != null) {
      widget.onSave!(formula);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 公式输入框
        TextField(
          controller: _controller,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: l10n.formulaSettings,
            hintText: l10n.formulaPlaceholder,
            errorText: _errorMessage,
            border: const OutlineInputBorder(),
            helperText: l10n.useRmbVariable,
          ),
          maxLines: 2,
        ),

        const SizedBox(height: 16),

        // 说明文字
        Text(
          l10n.supportedOperators,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),

        const SizedBox(height: 16),

        // 预览结果
        if (_previewResults != null) ...[
          Text(
            l10n.previewCalculationResult,
            style: const TextStyle(
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
          Text(
            l10n.formulaHistory,
            style: const TextStyle(
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
                onPressed: widget.enabled ? () => _onHistoryFormulaTap(formula) : null,
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
              onPressed: widget.enabled ? _onSave : null,
              child: Text(l10n.save),
            ),
          ),
      ],
    );
  }
}
