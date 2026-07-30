import 'package:flutter/material.dart';
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
        subtitle: const Text('未加入团队 (点击匹配现场团队)'),
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

        return ListTile(
          leading: const Icon(Icons.group, color: Colors.blue),
          title: Text(l10n.teamInfo),
          subtitle: Text(teamName),
          trailing: OutlinedButton.icon(
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('修改团队'),
            onPressed: () => _showEditTeamDialog(
                context, ref, l10n, user, teamName == '加载团队中...' ? '' : teamName),
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
    final nameController = TextEditingController(text: currentTeamName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final teamService = ref.read(teamServiceProvider);

          return AlertDialog(
            title: const Text('修改 / 匹配现场团队'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: formKey,
                    child: TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '团队名称',
                        hintText: '输入或选择与现场买手一致的团队名称',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '团队名称不能为空';
                        }
                        if (value.trim().length < 2 || value.trim().length > 50) {
                          return '团队名称长度需在2-50字之间';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '已存在的现场团队 (点击直接快捷加入):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder(
                    future: teamService.getAllTeams(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }

                      final teams = snapshot.data ?? [];
                      if (teams.isEmpty) {
                        return const Text(
                          '暂无已存在的团队，您可以手动输入团队名创建',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      }

                      return Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: teams.map((team) {
                          final isSelected =
                              nameController.text.trim() == team.name;
                          return ChoiceChip(
                            label: Text(team.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  nameController.text = team.name;
                                });
                              }
                            },
                          );
                        }).toList(),
                      );
                    },
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
                    final newName = nameController.text.trim();
                    final teamService = ref.read(teamServiceProvider);

                    // 智能查找或创建同名团队，确保与现场买手同组
                    final team =
                        await teamService.getOrCreateTeamByName(name: newName);
                    await teamService.updateUserTeam(user.id, team.id);

                    // 刷新全局状态：包含当前用户数据、事件列表与当前活跃事件
                    ref.invalidate(currentUserDataProvider);
                    ref.invalidate(eventsProvider);
                    ref.invalidate(activeEventProvider);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已成功加入“$newName”团队，现场数据已自动同步')),
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
                child: const Text('保存'),
              ),
            ],
          );
        },
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
