import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/network_config.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'dart:async';

/// 网络状态服务
/// 监控 Supabase 连接状态并提供网络延迟信息
class NetworkStatusService extends ChangeNotifier {
  final SupabaseClient _client;
  Timer? _checkTimer;

  bool _isConnected = true;
  int _latencyMs = 0;
  DateTime? _lastCheckTime;
  bool _isDisposed = false;

  NetworkStatusService(this._client) {
    _startMonitoring();
  }

  bool get isConnected => _isConnected;
  int get latencyMs => _latencyMs;
  DateTime? get lastCheckTime => _lastCheckTime;

  /// 获取连接质量描述
  String get connectionQuality {
    if (!_isConnected) return '断线';
    if (_latencyMs < 200) return '良好';
    if (_latencyMs < 500) return '一般';
    if (_latencyMs < 1000) return '较慢';
    return '很慢';
  }

  /// 获取连接质量颜色
  Color get connectionColor {
    if (!_isConnected) return Colors.red;
    if (_latencyMs < 200) return Colors.green;
    if (_latencyMs < 500) return Colors.orange;
    return Colors.red;
  }

  /// 启动网络监控
  void _startMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(
      NetworkConfig.networkCheckInterval,
      (timer) async {
        if (_isDisposed) {
          timer.cancel();
          return;
        }
        await _checkConnection();
      },
    );
  }

  /// 检查网络连接
  Future<void> _checkConnection() async {
    if (_isDisposed) return;

    try {
      final startTime = DateTime.now();

      // 执行一个简单的查询测试连接
      await _client
          .from('users')
          .select('id')
          .limit(1)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('连接超时'),
          );

      final endTime = DateTime.now();
      final latency = endTime.difference(startTime).inMilliseconds;

      if (!_isDisposed) {
        _isConnected = true;
        _latencyMs = latency;
        _lastCheckTime = endTime;
        notifyListeners();
      }
    } catch (e) {
      if (!_isDisposed) {
        _isConnected = false;
        _latencyMs = 0;
        _lastCheckTime = DateTime.now();
        notifyListeners();
      }
    }
  }

  /// 手动刷新网络状态
  Future<void> refresh() async {
    await _checkConnection();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _checkTimer?.cancel();
    _checkTimer = null;
    super.dispose();
  }
}

/// 网络状态 Provider
final networkStatusServiceProvider = ChangeNotifierProvider<NetworkStatusService>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final service = NetworkStatusService(supabaseService.client);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
