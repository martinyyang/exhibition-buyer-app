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

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final userAsync = ref.watch(currentUserDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: const SafeBackButton(fallbackPath: '/events'),
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
              title: const Text('用户信息加载异常'),
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
        ],
      ),
    );
  }

  Widget _buildTeamTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    app_user.User user,
  ) {
    if (user.teamId == null || user.teamId!.isEmpty) {
      return ListTile(
        leading: const Icon(Icons.group_add, color: Colors.orange),
        title: Text(l10n.teamInfo),
        subtitle: const Text('未加入团队 (点击凭邀请码加入)'),
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
                ? '加载团队中...'
                : l10n.teamInfo);
        final code = team?.inviteCode;

        return ListTile(
          leading: const Icon(Icons.group, color: Colors.blue),
          title: Text(l10n.teamInfo),
          subtitle: Text(code != null ? '$teamName (邀请码: $code)' : teamName),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (code != null)
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: '复制团队邀请码',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已复制团队邀请码: $code')),
                    );
                  },
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('切换团队'),
                onPressed: () => _showEditTeamDialog(
                    context, ref, l10n, user, teamName == '加载团队中...' ? '' : teamName),
              ),
            ],
          ),
          onTap: () => _showEditTeamDialog(
              context, ref, l10n, user, teamName == '加载团队中...' ? '' : teamName),
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
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('凭邀请码 / 团队名切换团队'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔒 团队隐私隔离：请填入买手分享给您的 6 位团队邀请码（或准确团队全名）：',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Form(
                key: formKey,
                child: TextFormField(
                  controller: inputController,
                  decoration: const InputDecoration(
                    labelText: '团队邀请码 / 团队全名',
                    hintText: '例如: 3F8A91 或 苹果团队',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '邀请码或团队名称不能为空';
                    }
                    return null;
                  },
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
                final teamService = ref.read(teamServiceProvider);

                final team = await teamService.joinTeamByInviteCodeOrName(input);
                await teamService.updateUserTeam(user.id, team.id);

                ref.invalidate(currentUserDataProvider);
                ref.invalidate(eventsProvider);
                ref.invalidate(activeEventProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已成功加入“${team.name}”团队，现场数据已自动同步')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('修改团队失败: $e')),
                  );
                }
              }
            },
            child: const Text('验证并加入'),
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
