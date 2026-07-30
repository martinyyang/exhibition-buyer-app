import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../team/providers/team_provider.dart';
import '../../auth/models/user.dart' as app_user;

class EventSelectionScreen extends ConsumerStatefulWidget {
  const EventSelectionScreen({super.key});

  @override
  ConsumerState<EventSelectionScreen> createState() =>
      _EventSelectionScreenState();
}

class _EventSelectionScreenState extends ConsumerState<EventSelectionScreen> {
  bool _isCreating = false;

  void _showCreateEventDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? startDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.createNewEvent),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.eventName,
                    hintText: l10n.eventNameHint,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterEventName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.startDate),
                  subtitle: Text(
                    startDate != null
                        ? '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}'
                        : l10n.tapToSelectDate,
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() {
                        startDate = date;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  _createEvent(nameController.text, startDate);
                }
              },
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createEvent(String name, DateTime? startDate) async {
    final l10n = AppLocalizations.of(context)!;

    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectStartDate)),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final authService = ref.read(authServiceProvider);

      // 重试逻辑：有时注册后 team_id 更新需要时间
      String? teamId;
      for (int i = 0; i < 3; i++) {
        final user = await authService.getCurrentUser();
        teamId = user?.teamId;

        if (teamId != null) break;

        // 如果是第一次重试，等待 1 秒
        if (i < 2) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (teamId == null) {
        throw Exception(l10n.userNotInTeam);
      }

      final eventService = ref.read(eventServiceProvider);
      await eventService.createEvent(
        name: name,
        startDate: startDate,
        teamId: teamId,
        setAsActive: true,
      );

      // 手动刷新事件列表（防止 Realtime 未启用）
      if (mounted) {
        ref.invalidate(eventsProvider);
        ref.invalidate(activeEventProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.eventCreatedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.createFailed(e.toString())),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _onEventTap(Event event) async {
    // 如果点击的不是当前活动，先设置为活动
    if (!event.isActive) {
      await _setActiveEvent(event);
    }

    // 导航到摊位列表页面
    if (mounted) {
      context.go('/events/${event.id}/booths');
    }
  }

  void _onEventLongPress(Event event) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!event.isActive)
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: Text(l10n.setAsActive),
              onTap: () {
                Navigator.pop(context);
                _setActiveEvent(event);
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(l10n.edit),
            onTap: () {
              Navigator.pop(context);
              // TODO: 编辑场次
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteEvent(event);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _setActiveEvent(Event event) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final authService = ref.read(authServiceProvider);

      // 重试逻辑：有时注册后 team_id 更新需要时间
      String? teamId;
      for (int i = 0; i < 3; i++) {
        final user = await authService.getCurrentUser();
        teamId = user?.teamId;

        if (teamId != null) break;

        // 如果是第一次重试，等待 1 秒
        if (i < 2) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (teamId == null) {
        throw Exception(l10n.userNotInTeam);
      }

      final eventService = ref.read(eventServiceProvider);
      await eventService.setActiveEvent(event.id, teamId);

      // 手动刷新事件列表（防止 Realtime 未启用）
      if (mounted) {
        ref.invalidate(eventsProvider);
        ref.invalidate(activeEventProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.setActiveEventSuccess(event.name))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.setActiveFailed(e.toString()))),
        );
      }
    }
  }

  void _confirmDeleteEvent(Event event) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteEventMessage(event.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent(event);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(Event event) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final eventService = ref.read(eventServiceProvider);
      await eventService.deleteEvent(event.id);

      // 手动刷新事件列表（防止 Realtime 未启用）
      if (mounted) {
        ref.invalidate(eventsProvider);
        ref.invalidate(activeEventProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.eventDeletedSuccess(event.name))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deleteFailed(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eventsAsync = ref.watch(eventsProvider);
    final userAsync = ref.watch(currentUserDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventSelection),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _isCreating ? null : _showCreateEventDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          userAsync.when(
            data: (user) => _buildTeamHeader(context, ref, user),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noEvents,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noEventsRemoteTip,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.group_add),
                            label: Text(l10n.oneClickMatchTeam),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () {
                              final user = userAsync.value;
                              if (user != null) {
                                _showQuickTeamDialog(context, ref, user);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: event.isActive ? 4 : 1,
                      color: event.isActive ? Colors.green.shade50 : null,
                      child: InkWell(
                        onTap: () => _onEventTap(event),
                        onLongPress: () => _onEventLongPress(event),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              if (event.isActive)
                                Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    l10n.current,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${event.startDate.year}-${event.startDate.month.toString().padLeft(2, '0')}-${event.startDate.day.toString().padLeft(2, '0')}${event.endDate != null ? ' ${l10n.to} ${event.endDate!.year}-${event.endDate!.month.toString().padLeft(2, '0')}-${event.endDate!.day.toString().padLeft(2, '0')}' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(l10n.loadFailed(error.toString())),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(eventsProvider),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHeader(
    BuildContext context,
    WidgetRef ref,
    app_user.User? user,
  ) {
    if (user == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final teamService = ref.read(teamServiceProvider);

    return Container(
      width: double.infinity,
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.group, size: 20, color: Colors.blue.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: FutureBuilder(
              future: user.teamId != null
                  ? teamService.getTeam(user.teamId!)
                  : null,
              builder: (context, snapshot) {
                final team = snapshot.data;
                final teamName = team?.name ??
                    (user.teamId == null ? l10n.teamInfo : l10n.loading);
                final code = team?.inviteCode;

                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        code != null
                            ? '${l10n.currentTeamPrefix}$teamName ($code)'
                            : '${l10n.currentTeamPrefix}$teamName',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (code != null)
                      IconButton(
                        icon: const Icon(Icons.copy, size: 14),
                        tooltip: l10n.copyInviteCode,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(l10n.inviteCodeCopied(code))),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: Text(l10n.switchTeam, style: const TextStyle(fontSize: 12)),
            onPressed: () => _showQuickTeamDialog(context, ref, user),
          ),
        ],
      ),
    );
  }

  void _showQuickTeamDialog(
    BuildContext context,
    WidgetRef ref,
    app_user.User user,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final inputController = TextEditingController();
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
                child: TextFormField(
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
                final team =
                    await teamService.joinTeamByInviteCodeOrName(input);
                await teamService.updateUserTeam(user.id, team.id);

                ref.invalidate(currentUserDataProvider);
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
}
