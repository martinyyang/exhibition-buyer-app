import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase服务封装
/// 注意：不要直接使用 Supabase.instance，而是通过 SupabaseService 类
/// 在测试中可以mock这个服务
class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  /// 获取当前用户ID
  String? get currentUserId => _client.auth.currentUser?.id;

  /// 检查用户是否已登录
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// 获取Supabase客户端实例
  SupabaseClient get client => _client;
}
