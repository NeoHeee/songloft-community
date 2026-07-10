import 'package:flutter/material.dart';

/// 设置页分组卡片
class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 20, color: colorScheme.primary),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.28),
          ),
          ...children,
        ],
      ),
    );
  }
}
