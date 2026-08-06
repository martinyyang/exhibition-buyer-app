import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                  _buildPresenceText(presences),
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

  String _buildPresenceText(List<UserPresence> presences) {
    if (presences.isEmpty) return '';

    final names = presences
        .map((p) => p.userName ?? p.userEmail ?? 'Unknown')
        .take(3)
        .toList();

    if (presences.length == 1) {
      return '${names[0]} 在线';
    } else if (presences.length <= 3) {
      return '${names.join('、')} 在线';
    } else {
      return '${names.join('、')} 等 ${presences.length} 人在线';
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
                _buildActivityText(otherUsers),
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

  String _buildActivityText(List<UserPresence> presences) {
    if (presences.isEmpty) return '';

    final names = presences
        .map((p) => p.userName ?? p.userEmail ?? 'Someone')
        .take(2)
        .toList();

    if (presences.length == 1) {
      return '${names[0]} 正在查看';
    } else if (presences.length == 2) {
      return '${names.join(' 和 ')} 正在查看';
    } else {
      return '${names.join('、')} 等 ${presences.length} 人正在查看';
    }
  }
}
