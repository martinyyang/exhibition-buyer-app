import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 安全返回按键组件
/// 优先调用 context.pop()；如果当前无法 pop (例如刷新或使用了 context.go)，
/// 则导航至指定的 fallbackPath，确保页面永远有合法的返回途径。
class SafeBackButton extends StatelessWidget {
  final String? fallbackPath;
  final Color? color;
  final VoidCallback? onPressed;

  const SafeBackButton({
    super.key,
    this.fallbackPath,
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      color: color,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
          return;
        }

        if (context.canPop()) {
          context.pop();
        } else if (fallbackPath != null && fallbackPath!.isNotEmpty) {
          context.go(fallbackPath!);
        } else {
          context.go('/events');
        }
      },
    );
  }
}
