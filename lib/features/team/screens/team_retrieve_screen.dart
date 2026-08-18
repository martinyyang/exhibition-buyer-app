import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/team_provider.dart';
import '../../auth/models/team.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../shared/widgets/onboarding_dialog.dart';

/// 通过密码找回团队邀请码的界面
class TeamRetrieveScreen extends ConsumerStatefulWidget {
  const TeamRetrieveScreen({super.key});

  @override
  ConsumerState<TeamRetrieveScreen> createState() => _TeamRetrieveScreenState();
}

class _TeamRetrieveScreenState extends ConsumerState<TeamRetrieveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  Team? _retrievedTeam;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOnboardingIfNeeded();
    });
  }

  Future<void> _showOnboardingIfNeeded() async {
    final onboardingService = ref.read(onboardingServiceProvider);
    final hasSeenOnboarding =
        await onboardingService.hasSeenOnboarding('team_retrieve');

    if (!hasSeenOnboarding && mounted) {
      await _showOnboarding(markAsSeen: true);
    }
  }

  Future<void> _showOnboarding({bool markAsSeen = false}) async {
    await showDialog(
      context: context,
      builder: (context) => OnboardingDialog(
        title: '找回邀请码操作指南',
        tips: const [
          OnboardingTip(
            icon: Icons.security,
            title: '安全验证',
            description: '输入团队ID和密码进行验证，确保只有团队成员可以查看邀请码',
          ),
          OnboardingTip(
            icon: Icons.vpn_key,
            title: '获取邀请码',
            description: '验证成功后，系统将显示6位邀请码，可复制分享给新成员',
          ),
          OnboardingTip(
            icon: Icons.info_outline,
            title: '团队ID获取',
            description: '团队ID通常由团队创建者提供，或在团队设置中查看',
          ),
        ],
        onDismiss: () {
          if (markAsSeen) {
            ref
                .read(onboardingServiceProvider)
                .markOnboardingSeen('team_retrieve');
          }
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  void dispose() {
    _teamIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final teamService = ref.read(teamServiceProvider);
      final team = await teamService.verifyTeamPassword(
        teamId: _teamIdController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (team == null) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.passwordIncorrect),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _retrievedTeam = team;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
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

  void _copyInviteCode() {
    if (_retrievedTeam != null) {
      Clipboard.setData(ClipboardData(text: _retrievedTeam!.inviteCode));
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.inviteCodeCopied(_retrievedTeam!.inviteCode))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.retrieveInviteCode),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showOnboarding(markAsSeen: false),
            tooltip: '查看操作指南',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.key,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.retrieveInviteCode,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.enterTeamPassword,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_retrievedTeam == null) ...[
                  TextFormField(
                    controller: _teamIdController,
                    decoration: InputDecoration(
                      labelText: l10n.inviteCode,
                      hintText: 'e.g., 3F8A91',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.badge),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.teamCodeOrNameRequired;
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: l10n.teamPassword,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.pleaseEnterPassword;
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyPassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.verify,
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${l10n.teamName}: ${_retrievedTeam!.name}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          l10n.inviteCode,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SelectableText(
                            _retrievedTeam!.inviteCode,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _copyInviteCode,
                          icon: const Icon(Icons.copy),
                          label: Text(l10n.copyInviteCode),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _retrievedTeam = null;
                        _teamIdController.clear();
                        _passwordController.clear();
                      });
                    },
                    child: Text(l10n.retrieveInviteCode),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
