import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_presence_service.dart';
import '../providers/presence_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// 用户在线状态管理 Mixin
/// 在 StatefulWidget 中使用此 Mixin 自动管理用户在线状态
mixin PresenceManagerMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  Timer? _heartbeatTimer;
  String? _currentScreen;
  Map<String, dynamic>? _currentContext;

  /// 子类需要实现：返回当前页面标识符
  String get screenIdentifier;

  /// 子类可选实现：返回当前页面上下文
  Map<String, dynamic>? get screenContext => null;

  @override
  void initState() {
    super.initState();
    _currentScreen = screenIdentifier;
    _currentContext = screenContext;
    _setOnline();
    _startHeartbeat();
  }

  @override
  void dispose() {
    _stopHeartbeat();
    _setOffline();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果上下文变化，更新在线状态
    final newContext = screenContext;
    if (newContext.toString() != _currentContext.toString()) {
      _currentContext = newContext;
      _updatePresence();
    }
  }

  Future<void> _setOnline() async {
    final presenceService = ref.read(userPresenceServiceProvider);
    final userData = await ref.read(currentUserDataProvider.future);
    final user = ref.read(currentUserProvider).asData?.value.session?.user;

    if (user != null && userData?.teamId != null) {
      await presenceService.setOnline(
        userId: user.id,
        teamId: userData!.teamId!,
        currentScreen: _currentScreen,
        currentContext: _currentContext,
      );
    }
  }

  Future<void> _setOffline() async {
    final presenceService = ref.read(userPresenceServiceProvider);
    final userData = await ref.read(currentUserDataProvider.future);
    final user = ref.read(currentUserProvider).asData?.value.session?.user;

    if (user != null && userData?.teamId != null) {
      await presenceService.setOffline(
        userId: user.id,
        teamId: userData!.teamId!,
      );
    }
  }

  Future<void> _updatePresence() async {
    final presenceService = ref.read(userPresenceServiceProvider);
    final userData = await ref.read(currentUserDataProvider.future);
    final user = ref.read(currentUserProvider).asData?.value.session?.user;

    if (user != null && userData?.teamId != null) {
      await presenceService.heartbeat(
        userId: user.id,
        teamId: userData!.teamId!,
        currentScreen: _currentScreen,
        currentContext: _currentContext,
      );
    }
  }

  void _startHeartbeat() {
    // 每 30 秒发送一次心跳
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updatePresence();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}
