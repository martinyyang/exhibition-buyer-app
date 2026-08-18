import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../providers/team_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../shared/widgets/onboarding_dialog.dart';

class TeamCreateScreen extends ConsumerStatefulWidget {
  const TeamCreateScreen({super.key});

  @override
  ConsumerState<TeamCreateScreen> createState() => _TeamCreateScreenState();
}

class _TeamCreateScreenState extends ConsumerState<TeamCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _createdTeamId;
  String? _createdInviteCode;

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
        await onboardingService.hasSeenOnboarding('team_create');

    if (!hasSeenOnboarding && mounted) {
      await _showOnboarding(markAsSeen: true);
    }
  }

  Future<void> _showOnboarding({bool markAsSeen = false}) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (context) => OnboardingDialog(
        title: l10n.onboardingTitleTeamCreate,
        tips: const [
          OnboardingTip(
            icon: Icons.business,
            title: '设置团队名称',
            description: '输入一个有意义的团队名称，方便团队成员识别',
          ),
          OnboardingTip(
            icon: Icons.lock,
            title: '设置团队密码',
            description: '设置一个安全的密码保护您的团队，密码将用于团队成员加入验证',
          ),
          OnboardingTip(
            icon: Icons.vpn_key,
            title: '分享邀请码',
            description: '创建成功后，将自动生成6位邀请码，分享给团队成员即可快速加入',
          ),
        ],
        onDismiss: () {
          if (markAsSeen) {
            ref
                .read(onboardingServiceProvider)
                .markOnboardingSeen('team_create');
          }
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final teamService = ref.read(teamServiceProvider);
      final password = _passwordController.text.trim();
      final team = await teamService.createTeam(
        name: _teamNameController.text.trim(),
        password: password,
      );

      // 刷新用户状态
      ref.invalidate(currentUserDataProvider);

      setState(() {
        _createdTeamId = team.id;
        _createdInviteCode = team.inviteCode;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.teamCreationSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.createFailed(e.toString())}'),
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
    if (_createdInviteCode != null) {
      Clipboard.setData(ClipboardData(text: _createdInviteCode!));
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.inviteCodeCopied(_createdInviteCode ?? ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createTeam),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showOnboarding(markAsSeen: false),
            tooltip: l10n.helpGuide,
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
                  Icons.group_add,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.createNewTeam,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.teamCreationSuccess,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_createdTeamId == null) ...[
                  TextFormField(
                    controller: _teamNameController,
                    decoration: InputDecoration(
                      labelText: l10n.teamName,
                      hintText: l10n.teamNameHint,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.pleaseEnterTeamName;
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
                      hintText: l10n.teamPasswordHint,
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
                    onPressed: _isLoading ? null : _createTeam,
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
                            l10n.createTeam,
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
                          l10n.teamCreatedSuccessMessage,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.teamName}: ${_teamNameController.text}',
                          style: const TextStyle(fontSize: 16),
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
                            _createdInviteCode!,
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
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _createdInviteCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(l10n.inviteCodeCopied(
                                      _createdInviteCode ?? ''))),
                            );
                          },
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
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          l10n.teamPassword,
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
                            _passwordController.text,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _passwordController.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.passwordCopied)),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: Text(l10n.copyPassword),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.shareTeamIdMessage,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.go('/events');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      l10n.continueToApp,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _createdTeamId = null;
                        _teamNameController.clear();
                        _passwordController.clear();
                      });
                    },
                    child: Text(l10n.createAnotherTeam),
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
