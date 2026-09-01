import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/flag.dart';
import '../utils/user_color_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 用户颜色图例，显示每个标注者的颜色映射
class UserColorLegend extends StatefulWidget {
  final List<Flag> flags;

  const UserColorLegend({
    required this.flags,
    super.key,
  });

  @override
  State<UserColorLegend> createState() => _UserColorLegendState();
}

class _UserColorLegendState extends State<UserColorLegend> {
  Map<String, String> _userNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserNames();
  }

  @override
  void didUpdateWidget(UserColorLegend oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果标注用户列表变化，重新加载
    final oldUserIds = oldWidget.flags.map((f) => f.createdBy).toSet();
    final newUserIds = widget.flags.map((f) => f.createdBy).toSet();
    if (oldUserIds.difference(newUserIds).isNotEmpty ||
        newUserIds.difference(oldUserIds).isNotEmpty) {
      _loadUserNames();
    }
  }

  Future<void> _loadUserNames() async {
    final userIds = widget.flags.map((f) => f.createdBy).toSet().toList();
    if (userIds.isEmpty) {
      setState(() {
        _userNames = {};
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('id, email, role')
          .inFilter('id', userIds);

      final names = <String, String>{};
      for (final row in response) {
        final email = row['email'] as String?;
        final role = row['role'] as String?;

        // 提取邮箱前缀（@之前的部分）
        String displayName = 'Unknown';
        if (email != null && email.contains('@')) {
          displayName = email.split('@')[0];
        }

        // 添加角色标识
        if (role == 'buyer') {
          displayName = '$displayName 🏪'; // 现场买手
        } else if (role == 'remote') {
          displayName = '$displayName 🏠'; // 远程
        }

        names[row['id'] as String] = displayName;
      }

      setState(() {
        _userNames = names;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load user names: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 40,
        child: Center(
            child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    // 获取唯一的用户列表
    final uniqueUserIds = widget.flags.map((f) => f.createdBy).toSet().toList();
    if (uniqueUserIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: uniqueUserIds.map((userId) {
          final color = UserColorMapper.getColorForUser(userId);
          final l10n = AppLocalizations.of(context)!;
          final rawName = _userNames[userId] ?? 'Unknown';
          final name = rawName == 'Unknown' ? l10n.unknownUser : rawName;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 颜色圆点
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // 用户名
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
