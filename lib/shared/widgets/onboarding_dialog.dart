import 'package:flutter/material.dart';

class OnboardingTip {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingTip({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class OnboardingDialog extends StatelessWidget {
  final String title;
  final List<OnboardingTip> tips;
  final VoidCallback onDismiss;

  const OnboardingDialog({
    super.key,
    required this.title,
    required this.tips,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < tips.length; i++) ...[
              if (i > 0) const Divider(height: 24),
              _TipItem(tip: tips[i]),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('知道了'),
        ),
      ],
    );
  }
}

class _TipItem extends StatelessWidget {
  final OnboardingTip tip;

  const _TipItem({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            tip.icon,
            size: 24,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tip.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tip.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
