import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/formula_provider.dart';
import '../widgets/formula_input.dart';
import '../../../shared/widgets/safe_back_button.dart';

class FormulaManagementScreen extends ConsumerWidget {
  const FormulaManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserDataProvider);
    final teamId = currentUser.value?.teamId;

    if (teamId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.exchangeFormulaManagement)),
        body: Center(child: Text(l10n.teamInfoNotFound)),
      );
    }

    final currentFormulaAsync = ref.watch(currentFormulaProvider(teamId));
    final historyAsync = ref.watch(formulaHistoryProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exchangeFormulaManagement),
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
                      Text(
                        l10n.currentFormula,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      currentFormulaAsync.when(
                        data: (formula) {
                          if (formula == null || formula.isEmpty) {
                            return Text(
                              l10n.noFormulaSet,
                              style: const TextStyle(
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
                          l10n.loadFailed(err.toString()),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 公式输入区域
              Text(
                l10n.setNewFormula,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              historyAsync.when(
                data: (history) => FormulaInput(
                  initialFormula: currentFormulaAsync.value,
                  historyFormulas: history,
                  onSave: (formula) =>
                      _saveFormula(context, ref, teamId, formula),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                    Text(l10n.loadHistoryFailed(err.toString())),
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
    final l10n = AppLocalizations.of(context)!;
    try {
      final settingsService = ref.read(exchangeSettingsServiceProvider);
      await settingsService.updateFormula(teamId, formula);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.formulaSavedSuccess)),
        );
      }

      // 刷新数据
      ref.invalidate(currentFormulaProvider(teamId));
      ref.invalidate(formulaHistoryProvider(teamId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveFailed(e.toString()))),
        );
      }
    }
  }

  void _showFormulaHelp(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.formulaInstructions),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.formulaInstructions,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(l10n.formulaInstructionRmb),
              Text(l10n.formulaInstructionOperators),
              const SizedBox(height: 16),
              Text(
                l10n.formulaExamples,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildFormulaExample('RMB * 0.14', l10n.formulaExampleSimple),
              _buildFormulaExample(
                  '(RMB - 50) * 0.14', l10n.formulaExampleDeduct),
              _buildFormulaExample(
                  'RMB * 0.14 + 10', l10n.formulaExampleAddFee),
              _buildFormulaExample(
                  '(RMB * 0.14 + 10) * 1.1', l10n.formulaExampleComplex),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.gotIt),
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
