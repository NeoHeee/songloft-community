import 'package:flutter/material.dart';

import 'tv_focusable.dart';

class TvActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool destructive;

  const TvActionItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });
}

/// 遥控器友好的操作菜单。
///
/// 首项自动获得焦点，确认后先关闭弹窗再执行操作，返回键仅关闭菜单。
Future<void> showTvActionDialog({
  required BuildContext context,
  required String title,
  required List<TvActionItem> actions,
}) {
  if (actions.isEmpty) return Future<void>.value();

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final colorScheme = theme.colorScheme;

      return AlertDialog(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        contentPadding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 360, maxWidth: 480),
          child: FocusTraversalGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  TvFocusable(
                    autofocus: index == 0,
                    focusedScale: 1.02,
                    borderRadius: 14,
                    onSelect: () {
                      final action = actions[index].onPressed;
                      Navigator.of(dialogContext).pop();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        action();
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            actions[index].icon,
                            color:
                                actions[index].destructive
                                    ? colorScheme.error
                                    : colorScheme.primary,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              actions[index].label,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color:
                                    actions[index].destructive
                                        ? colorScheme.error
                                        : null,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (index < actions.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
