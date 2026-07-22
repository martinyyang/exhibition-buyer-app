import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase客户端单例
final supabaseClient = Supabase.instance.client;

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
