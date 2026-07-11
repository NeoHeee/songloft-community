import 'package:flutter/material.dart';

import '../../core/theme/tv_theme.dart';

/// TV 端统一图标底板。
///
/// 用于首页快捷入口、设置分类、空状态和封面占位，统一图标尺寸、
/// 圆角、背景和边框，避免不同页面各自定义后出现大小不一致。
class TvIconSurface extends StatelessWidget {
  final Widget icon;
  final double size;
  final double iconSize;
  final Color? accentColor;
  final bool selected;
  final bool circular;
  final double? radius;

  const TvIconSurface({
    super.key,
    required this.icon,
    this.size = TvTheme.iconSurfaceMedium,
    this.iconSize = TvTheme.iconSizeMedium,
    this.accentColor,
    this.selected = false,
    this.circular = false,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? colorScheme.primary;
    final borderRadius =
        circular
            ? BorderRadius.circular(size / 2)
            : BorderRadius.circular(radius ?? TvTheme.iconSurfaceRadius);

    return AnimatedContainer(
      duration: TvTheme.focusAnimationDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:
            selected
                ? accent.withValues(alpha: 0.18)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.82),
        borderRadius: borderRadius,
        border: Border.all(
          color:
              selected
                  ? accent.withValues(alpha: 0.5)
                  : colorScheme.outlineVariant.withValues(alpha: 0.26),
        ),
        boxShadow:
            selected
                ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.16),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
                : null,
      ),
      child: IconTheme.merge(
        data: IconThemeData(
          size: iconSize,
          color: selected ? accent : colorScheme.onSurfaceVariant,
        ),
        child: Center(child: icon),
      ),
    );
  }
}
