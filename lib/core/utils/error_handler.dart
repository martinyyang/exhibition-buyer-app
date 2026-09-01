import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 统一错误处理工具
/// 将技术错误转换为用户友好的提示信息
class ErrorHandler {
  /// 将异常转换为用户友好的错误信息
  static String getUserMessage(AppLocalizations l10n, dynamic error) {
    if (error is TimeoutException) {
      return l10n.networkTimeoutMsg;
    } else if (error.toString().contains('NetworkException') ||
        error.toString().contains('SocketException') ||
        error.toString().contains('Failed host lookup')) {
      return l10n.networkFailedMsg;
    } else if (error is PostgrestException) {
      if (error.code == '23505') {
        return l10n.dataExistsMsg;
      } else if (error.code == '42P01') {
        return l10n.tableNotFoundMsg;
      } else if (error.code == 'PGRST301') {
        return l10n.noPermissionMsg;
      }
      return l10n.dataSaveFailedMsg;
    } else if (error is StorageException) {
      if (error.message.contains('exceeded')) {
        return l10n.fileTooLargeMsg;
      } else if (error.message.contains('not found')) {
        return l10n.fileNotFoundMsg;
      }
      return l10n.fileUploadFailedMsg;
    } else if (error.toString().contains('超时')) {
      return l10n.operationTimeoutMsg;
    }

    // 默认错误信息
    return l10n.operationFailedMsg;
  }

  /// 显示错误提示（带可选的重试按钮）
  static void show(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getUserMessage(l10n, error)),
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: l10n.retry,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}
