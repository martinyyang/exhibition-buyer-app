import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/locale_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../team/providers/team_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
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
          FutureBuilder(
            future: ref.read(authServiceProvider).getCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final user = snapshot.data;
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
                  if (user.teamId != null)
                    FutureBuilder(
                      future: ref.read(teamServiceProvider).getTeam(user.teamId!),
                      builder: (context, teamSnapshot) {
                        final team = teamSnapshot.data;
                        if (team == null) {
                          return const SizedBox.shrink();
                        }
                        return ListTile(
                          leading: const Icon(Icons.group),
                          title: Text(l10n.teamInfo),
                          subtitle: Text(team.name),
                        );
                      },
                    ),
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
            subtitle: Text(
              currentLocale.languageCode == 'zh'
                ? l10n.languageChinese
                : l10n.languageEnglish
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showLanguageDialog(context, ref, l10n, currentLocale);
            },
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
