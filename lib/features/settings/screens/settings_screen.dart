import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/locale_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../team/providers/team_provider.dart';

import '../../../shared/widgets/safe_back_button.dart';
import '../../auth/models/user.dart' as app_user;
import '../../event/providers/event_provider.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../shared/widgets/onboarding_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final userAsync = ref.watch(currentUserDataProvider);

    // 显示入门引导（如果需要）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOnboardingIfNeeded(context, ref);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: const SafeBackButton(fallbackPath: '/events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showOnboarding(context, ref, markAsSeen: false),
            tooltip: l10n.helpGuide,
          ),
        ],
      ),
      body: ListView(
        children: [
          // Account Settings Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.accountSettings,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          userAsync.when(
            data: (user) {
              if (user == null) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(l10n.currentUser),
                    subtitle: Text(user.email),
                  ),
                  ListTile(
                    leading: const Icon(Icons.badge),
                    title: Text(l10n.userRole),
                    subtitle: Text(user.isBuyer ? l10n.buyer : l10n.remote),
                  ),
                  _buildTeamTile(context, ref, l10n, user),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      l10n.logout,
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: () => _showLogoutDialog(context, ref, l10n),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: Text(l10n.loadFailed('User info')),
              subtitle: Text(error.toString()),
            ),
          ),
          const Divider(),
          // General Settings Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.settings,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(currentLocale.languageCode == 'zh'
                ? l10n.languageChinese
                : l10n.languageEnglish),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showLanguageDialog(context, ref, l10n, currentLocale);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calculate),
            title: Text(l10n.formulaSettings),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/formula');
            },
          ),
        ],
      ),
    );
  }

  static Future<void> _showOnboardingIfNeeded(
      BuildContext context, WidgetRef ref) async {
    final onboardingService = ref.read(onboardingServiceProvider);
    final hasSeenOnboarding =
        await onboardingService.hasSeenOnboarding('settings');

    if (!context.mounted) return;
    if (!hasSeenOnboarding) {
      await _showOnboarding(context, ref, markAsSeen: true);
    }
  }

  static Future<void> _showOnboarding(BuildContext context, WidgetRef ref,
      {bool markAsSeen = false}) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (context) => OnboardingDialog(
        title: l10n.onboardingTitleSettings,
        tips: const [
          OnboardingTip(
            icon: Icons.group,
            title: '团队管理',
            description: '查看当前团队信息、复制邀请码或切换到其他团队',
          ),
          OnboardingTip(
            icon: Icons.language,
            title: '语言设置',
            description: '切换应用界面语言（中文/English）',
          ),
          OnboardingTip(
            icon: Icons.calculate,
            title: '价格公式',
            description: '配置团队级别的价格转换公式和汇率设置',
          ),
        ],
        onDismiss: () {
          if (markAsSeen) {
            ref.read(onboardingServiceProvider).markOnboardingSeen('settings');
          }
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildTeamTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    app_user.User initialUser,
  ) {
    // 实时监听最新的 user 对象，防止旧 user 闭包缓存导致 teamId 不更新
    final userAsync = ref.watch(currentUserDataProvider);
    final user = userAsync.value ?? initialUser;

    if (user.teamId == null || user.teamId!.isEmpty) {
      return ListTile(
        leading: const Icon(Icons.group_add, color: Colors.orange),
        title: Text(l10n.teamInfo),
        subtitle: Text(l10n.notInTeamTip),
        trailing: const Icon(Icons.add_circle_outline, color: Colors.orange),
        onTap: () => _showEditTeamDialog(context, ref, l10n, user, ''),
      );
    }

    return FutureBuilder(
      future: ref.read(teamServiceProvider).getTeam(user.teamId!),
      builder: (context, teamSnapshot) {
        final team = teamSnapshot.data;
        final teamName = team?.name ??
            (teamSnapshot.connectionState == ConnectionState.waiting
                ? l10n.loading
                : l10n.teamInfo);
        final code = team?.inviteCode;

        return ListTile(
          leading: const Icon(Icons.group, color: Colors.blue),
          title: Text(l10n.teamInfo),
          subtitle: Text(code != null ? '$teamName (Code: $code)' : teamName),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (code != null)
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: l10n.copyInviteCode,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.inviteCodeCopied(code))),
                    );
                  },
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 14),
                label: Text(l10n.switchTeam),
                onPressed: () => _showEditTeamDialog(context, ref, l10n, user,
                    teamName == l10n.loading ? '' : teamName),
              ),
            ],
          ),
          onTap: () => _showEditTeamDialog(context, ref, l10n, user,
              teamName == l10n.loading ? '' : teamName),
        );
      },
    );
  }

  void _showEditTeamDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    app_user.User user,
    String currentTeamName,
  ) {
    final inputController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.joinTeamTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.teamPrivacyTip,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: inputController,
                      decoration: InputDecoration(
                        labelText: l10n.inviteCodeOrNameLabel,
                        hintText: l10n.inviteCodeOrNameHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.vpn_key),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.teamCodeOrNameRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext);

              try {
                final input = inputController.text.trim();
                final password = passwordController.text.trim();
                final teamService = ref.read(teamServiceProvider);

                final team = await teamService.joinTeamByInviteCodeOrName(
                  input,
                  password: password,
                );

                // 强制多重刷所有用户与团队相关的 Provider
                ref.invalidate(currentUserDataProvider);
                ref.invalidate(currentTeamProvider);
                ref.invalidate(teamMembersProvider);
                ref.invalidate(eventsProvider);
                ref.invalidate(activeEventProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.teamJoinSuccess(team.name))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.teamJoinFailed(e.toString()))),
                  );
                }
              }
            },
            child: Text(l10n.verifyAndJoin),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmLogout),
        content: Text(l10n.confirmLogoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout(context, ref, l10n);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.logoutSuccess)),
        );
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.logoutFailed(e.toString()))),
        );
      }
    }
  }

  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Locale currentLocale,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(l10n.languageChinese),
              value: 'zh',
              groupValue: currentLocale.languageCode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).setLocale(Locale(value));
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.languageEnglish),
              value: 'en',
              groupValue: currentLocale.languageCode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).setLocale(Locale(value));
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
