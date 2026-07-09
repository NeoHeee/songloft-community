import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PluginIcon extends StatelessWidget {
  final String? iconUrl;
  final String displayName;
  final double size;
  final Color? statusColor;

  const PluginIcon({
    super.key,
    this.iconUrl,
    required this.displayName,
    this.size = 40,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    if (iconUrl != null && iconUrl!.isNotEmpty) {
      final url = iconUrl!;
      final isSvg = url.toLowerCase().endsWith('.svg');
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 5),
        child: isSvg
            ? SvgPicture.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.contain,
                placeholderBuilder: (_) => _buildFallback(),
                errorBuilder: (_, _, _) => _buildFallback(),
              )
            : ExcludeSemantics(
                child: Image.network(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildFallback(),
                ),
              ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    final color = statusColor ?? _generateColor();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.extension, color: color, size: size * 0.6),
    );
  }

  Color _generateColor() {
    final hash = displayName.hashCode;
    final hue = (hash % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
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
    final iconColor = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final fallback = IconTheme.merge(
      data: IconThemeData(color: iconColor, size: size),
      child: fallbackIcon,
    );

    Widget content = fallback;
    if (iconUrl != null && iconUrl!.isNotEmpty) {
      final url = iconUrl!;
      final isSvg = url.toLowerCase().endsWith('.svg');
      content = isSvg
          ? SvgPicture.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.contain,
              placeholderBuilder: (_) => fallback,
              errorBuilder: (_, _, _) => fallback,
            )
          : ExcludeSemantics(
              child: Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
            );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: size + 10,
      height: size + 10,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.72)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.34)
              : colorScheme.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: content),
        ),
      ),
    );
  }
}
