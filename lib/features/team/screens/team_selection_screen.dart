import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/team_provider.dart';

class TeamSelectionScreen extends ConsumerStatefulWidget {
  const TeamSelectionScreen({super.key});

  @override
  ConsumerState<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends ConsumerState<TeamSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamIdentifierController = TextEditingController();
  final _teamPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _teamIdentifierController.dispose();
    _teamPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinTeam() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final identifier = _teamIdentifierController.text.trim();
      final password = _teamPasswordController.text.trim();

      await authService.joinTeamWithIdentifier(
        identifier: identifier,
        password: password,
      );

      // 刷新用户状态并等待完成
      ref.invalidate(currentUserDataProvider);

      // 等待 Provider 刷新完成
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.joinTeamSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // 加入团队成功后跳转到事件选择页面
        context.go('/events');
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.joinTeamFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
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

  void _navigateToCreateTeam() {
    context.push('/team-create');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectTeam),
        automaticallyImplyLeading: false, // 不显示返回按钮，强制用户选择团队
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.group,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.welcomeToApp,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.pleaseSelectTeamOption,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // 加入现有团队卡片
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.group,
                                color: Colors.green,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.joinExistingTeam,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _teamIdentifierController,
                            decoration: InputDecoration(
                              labelText: l10n.teamNameOrInviteCode,
                              hintText: l10n.teamNameOrInviteCodeHint,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.group),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.pleaseEnterTeamNameOrInviteCode;
                              }
                              return null;
                            },
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _teamPasswordController,
                            decoration: InputDecoration(
                              labelText: l10n.teamPassword,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.pleaseEnterTeamPassword;
                              }
                              return null;
                            },
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 20),
                          if (_isLoading)
                            const Center(child: LoadingIndicator())
                          else
                            ElevatedButton(
                              onPressed: _handleJoinTeam,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                l10n.joinTeam,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // 创建新团队按钮
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _navigateToCreateTeam,
                  icon: const Icon(Icons.group_add, size: 24),
                  label: Text(
                    l10n.createNewTeam,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.blue, width: 2),
                    foregroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
