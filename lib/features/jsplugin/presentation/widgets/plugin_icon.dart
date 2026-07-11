import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../config/app_config.dart';
import '../../../../core/theme/tv_theme.dart';

/// 插件图标统一渲染组件。
///
/// SVG 使用留白完整展示，位图使用封面裁切；加载中和失败时均使用稳定的
/// 扩展图标占位，避免 TV 页面出现空白或尺寸跳动。
class PluginIcon extends StatelessWidget {
  final String? iconUrl;
  final String displayName;
  final double size;
  final Color? statusColor;
  final bool selected;
  final bool showSurface;

  const PluginIcon({
    super.key,
    this.iconUrl,
    required this.displayName,
    this.size = 40,
    this.statusColor,
    this.selected = false,
    this.showSurface = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = statusColor ?? _generateColor();
    final radius = (size * 0.24).clamp(8.0, 20.0);
    final padding = (size * 0.12).clamp(4.0, 10.0);

    final content = _buildNetworkIcon(context, accent, padding);
    if (!showSurface) return content;

    return AnimatedContainer(
      duration: TvTheme.focusAnimationDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:
            selected
                ? accent.withValues(alpha: 0.18)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color:
              selected
                  ? accent.withValues(alpha: 0.52)
                  : colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
        boxShadow:
            selected
                ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
                : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(padding: EdgeInsets.all(padding), child: content),
          if (statusColor != null)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: (size * 0.18).clamp(8.0, 14.0),
                height: (size * 0.18).clamp(8.0, 14.0),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNetworkIcon(BuildContext context, Color accent, double padding) {
    final fallback = _buildFallback(context, accent);
    final url = iconUrl?.trim();
    if (url == null || url.isEmpty) return fallback;

    final isSvg =
        Uri.tryParse(url)?.path.toLowerCase().endsWith('.svg') ??
        url.toLowerCase().contains('.svg');
    final innerSize = size - padding * 2;

    if (isSvg) {
      return SvgPicture.network(
        url,
        width: innerSize,
        height: innerSize,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => fallback,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    return ExcludeSemantics(
      child: Image.network(
        url,
        width: innerSize,
        height: innerSize,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return fallback;
        },
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }

  Widget _buildFallback(BuildContext context, Color color) {
    return Center(
      child: Icon(
        Icons.extension_rounded,
        color: color,
        size: size * 0.5,
        semanticLabel: displayName,
      ),
    );
  }

  Color _generateColor() {
    final hash = displayName.hashCode;
    final hue = (hash % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.58, 0.52).toColor();
  }
}

class PluginNavIcon extends StatelessWidget {
  final String? iconUrl;
  final double size;
  final Widget fallbackIcon;
  final bool selected;

  const PluginNavIcon({
    super.key,
    this.iconUrl,
    this.size = 24,
    required this.fallbackIcon,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveSize =
        AppConfig.isTvMode
            ? size.clamp(TvTheme.iconSizeMedium, 40).toDouble()
            : size;
    final iconColor =
        selected ? colorScheme.primary : colorScheme.onSurfaceVariant;
    final fallback = IconTheme.merge(
      data: IconThemeData(color: iconColor, size: effectiveSize),
      child: fallbackIcon,
    );

    Widget content = fallback;
    final url = iconUrl?.trim();
    if (url != null && url.isNotEmpty) {
      final isSvg =
          Uri.tryParse(url)?.path.toLowerCase().endsWith('.svg') ??
          url.toLowerCase().contains('.svg');
      content =
          isSvg
              ? SvgPicture.network(
                url,
                width: effectiveSize,
                height: effectiveSize,
                fit: BoxFit.contain,
                placeholderBuilder: (_) => fallback,
                errorBuilder: (_, _, _) => fallback,
              )
              : ExcludeSemantics(
                child: Image.network(
                  url,
                  width: effectiveSize,
                  height: effectiveSize,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => fallback,
                ),
              );
    }

    final surfacePadding = AppConfig.isTvMode ? 7.0 : 5.0;
    return AnimatedContainer(
      duration: TvTheme.focusAnimationDuration,
      curve: TvTheme.focusAnimationCurve,
      width: effectiveSize + surfacePadding * 2,
      height: effectiveSize + surfacePadding * 2,
      padding: EdgeInsets.all(surfacePadding),
      decoration: BoxDecoration(
        color:
            selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.78)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(AppConfig.isTvMode ? 13 : 10),
        border: Border.all(
          color:
              selected
                  ? colorScheme.primary.withValues(alpha: 0.42)
                  : colorScheme.outlineVariant.withValues(alpha: 0.26),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConfig.isTvMode ? 8 : 6),
        child: SizedBox(
          width: effectiveSize,
          height: effectiveSize,
          child: Center(child: content),
        ),
      ),
    );
  }
}
