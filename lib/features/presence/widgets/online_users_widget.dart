import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/user_presence.dart';
import '../providers/presence_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// 在线用户列表小部件
class OnlineUsersList extends ConsumerWidget {
  final String teamId;

  const OnlineUsersList({
    required this.teamId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenceAsync = ref.watch(teamPresenceProvider(teamId));
    final l10n = AppLocalizations.of(context)!;

    return presenceAsync.when(
      data: (presences) {
        if (presences.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.green.shade200),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.circle, color: Colors.green.shade600, size: 12),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _buildPresenceText(presences, l10n),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _buildPresenceText(
      List<UserPresence> presences, AppLocalizations l10n) {
    if (presences.isEmpty) return '';

    final names = presences
        .map((p) => p.userName ?? p.userEmail ?? 'Unknown')
        .take(3)
        .toList();

    if (presences.length == 1) {
      return l10n.onlineStatusSingle(names[0]);
    } else if (presences.length <= 3) {
      return l10n.onlineStatusFew(names.join(', '));
    } else {
      return l10n.onlineStatusMany(names.join(', '), presences.length);
    }
  }
}

/// 页面活动提示（谁正在查看这个页面）
class ScreenActivityIndicator extends ConsumerWidget {
  final String teamId;
  final String screen;
  final Map<String, dynamic>? context;

  const ScreenActivityIndicator({
    required this.teamId,
    required this.screen,
    this.context,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ScreenPresenceParams(
      teamId: teamId,
      screen: screen,
      context: this.context,
    );
    final presenceAsync = ref.watch(screenPresenceProvider(params));
    final l10n = AppLocalizations.of(context)!;

    return presenceAsync.when(
      data: (presences) {
        // 过滤掉当前用户
        final otherUsers = presences
            .where((p) =>
                p.userId !=
                ref.read(currentUserProvider).asData?.value.session?.user?.id)
            .toList();

        if (otherUsers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility, color: Colors.blue.shade700, size: 14),
              const SizedBox(width: 6),
              Text(
                _buildActivityText(otherUsers, l10n),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _buildActivityText(
      List<UserPresence> presences, AppLocalizations l10n) {
    if (presences.isEmpty) return '';

    final names = presences
        .map((p) => p.userName ?? p.userEmail ?? 'Someone')
        .take(2)
        .toList();

    if (presences.length == 1) {
      return l10n.viewingSingle(names[0]);
    } else if (presences.length == 2) {
      return l10n.viewingTwo(names.join(' & '));
    } else {
      return l10n.viewingMany(names.join(', '), presences.length);
    }
  }
}
