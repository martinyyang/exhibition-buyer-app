import 'package:flutter/material.dart';

class WarningBadge extends StatelessWidget {
  final bool show;
  final double size;

  const WarningBadge({
    super.key,
    required this.show,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return Icon(
      Icons.warning,
      color: Colors.red,
      size: size,
    );
  }
}
