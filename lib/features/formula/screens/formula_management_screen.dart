import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/formula_provider.dart';
import '../widgets/formula_input.dart';
import '../../../shared/widgets/safe_back_button.dart';

class FormulaManagementScreen extends ConsumerWidget {
  const FormulaManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserDataProvider);
    final teamId = currentUser.value?.teamId;

    if (teamId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('汇率公式管理')),
        body: const Center(child: Text('未找到团队信息')),
      );
    }

    final currentFormulaAsync = ref.watch(currentFormulaProvider(teamId));
    final historyAsync = ref.watch(formulaHistoryProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('汇率公式管理'),
        leading: const SafeBackButton(fallbackPath: '/events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showFormulaHelp(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 当前公式卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '当前使用的公式',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      currentFormulaAsync.when(
                        data: (formula) {
                          if (formula == null || formula.isEmpty) {
                            return const Text(
                              '尚未设置公式',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              formula,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (err, stack) => Text(
                          '加载失败: $err',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 公式输入区域
              const Text(
                '设置新公式',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              historyAsync.when(
                data: (history) => FormulaInput(
                  initialFormula: currentFormulaAsync.value,
                  historyFormulas: history,
                  onSave: (formula) => _saveFormula(context, ref, teamId, formula),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('加载历史记录失败: $err'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveFormula(
    BuildContext context,
    WidgetRef ref,
    String teamId,
    String formula,
  ) async {
    try {
      final settingsService = ref.read(exchangeSettingsServiceProvider);
      await settingsService.updateFormula(teamId, formula);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('公式保存成功')),
        );
      }

      // 刷新数据
      ref.invalidate(currentFormulaProvider(teamId));
      ref.invalidate(formulaHistoryProvider(teamId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  void _showFormulaHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('公式说明'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '如何编写公式：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• 使用 RMB 代表人民币价格'),
              const Text('• 支持运算符：+ - * / ( )'),
              const SizedBox(height: 16),
              const Text(
                '示例：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildFormulaExample('RMB * 0.14', '简单汇率换算'),
              _buildFormulaExample('(RMB - 50) * 0.14', '扣除费用后换算'),
              _buildFormulaExample('RMB * 0.14 + 10', '加上固定费用'),
              _buildFormulaExample('(RMB * 0.14 + 10) * 1.1', '复合计算'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaExample(String formula, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formula,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
