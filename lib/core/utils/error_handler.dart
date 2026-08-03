import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 统一错误处理工具
/// 将技术错误转换为用户友好的提示信息
class ErrorHandler {
  /// 将异常转换为用户友好的错误信息
  static String getUserMessage(dynamic error) {
    if (error is TimeoutException) {
      return '网络连接超时，请检查网络后重试';
    } else if (error.toString().contains('NetworkException') ||
        error.toString().contains('SocketException') ||
        error.toString().contains('Failed host lookup')) {
      return '网络连接失败，请检查网络后重试';
    } else if (error is PostgrestException) {
      if (error.code == '23505') {
        return '数据已存在';
      } else if (error.code == '42P01') {
        return '数据表不存在，请联系管理员';
      } else if (error.code == 'PGRST301') {
        return '无权限访问该资源';
      }
      return '数据保存失败，请稍后重试';
    } else if (error is StorageException) {
      if (error.message.contains('exceeded')) {
        return '文件大小超出限制';
      } else if (error.message.contains('not found')) {
        return '文件未找到';
      }
      return '文件上传失败，请稍后重试';
    } else if (error.toString().contains('超时')) {
      return '操作超时，请检查网络后重试';
    }

    // 默认错误信息
    return '操作失败，请稍后重试';
  }

  /// 显示错误提示（带可选的重试按钮）
  static void show(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getUserMessage(error)),
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: '重试',
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}
