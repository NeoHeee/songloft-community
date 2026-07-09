import 'package:flutter/material.dart';

import '../../core/theme/responsive.dart';
import 'adaptive_scaffold.dart';

/// 新版桌面/平板应用外壳。
///
/// 保留原有路由、播放器和队列逻辑，只重组视觉层级：
/// 左侧品牌导航、中间内容、右侧播放队列、底部悬浮播放坞。
class RedesignedDesktopShell extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavDestination> destinations;
  final Widget? bottomPlayer;
  final Widget? playlistDrawer;

  const RedesignedDesktopShell({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.bottomPlayer,
    this.playlistDrawer,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final isDesktop = screenType == ScreenType.desktop;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.055),
              Theme.of(context).scaffoldBackgroundColor,
              colorScheme.tertiary.withValues(alpha: 0.035),
            ],
          ),
        ),
        child: Row(
          children: [
            _Sidebar(
              compact: !isDesktop,
              destinations: destinations,
              currentIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              isDesktop ? 12 : 8,
                              10,
                              playlistDrawer == null ? 12 : 6,
                              0,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: ColoredBox(
                                color: colorScheme.surface.withValues(alpha: 0.72),
                                child: body,
                              ),
                            ),
                          ),
                        ),
                        if (playlistDrawer != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 10, 12, 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: playlistDrawer!,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (bottomPlayer != null) bottomPlayer!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final bool compact;
  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const _Sidebar({
    required this.compact,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: compact ? 94 : 256,
      margin: const EdgeInsets.fromLTRB(12, 10, 0, 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          _BrandHeader(compact: compact),
          Padding(
            padding: EdgeInsets.fromLTRB(compact ? 10 : 16, 8, compact ? 10 : 16, 8),
            child: Divider(
              color: colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
          if (!compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
              child: Text(
                '你的音乐',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical: 4,
              ),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final destination = destinations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _SidebarItem(
                    compact: compact,
                    destination: destination,
                    selected: currentIndex == index,
                    onTap: () => onDestinationSelected(index),
                  ),
                );
              },
            ),
          ),
          _LibraryStatus(compact: compact),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final bool compact;

  const _BrandHeader({required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 17 : 20, 22, compact ? 17 : 20, 8),
      child: Row(
        mainAxisAlignment:
            compact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorScheme.primary, colorScheme.tertiary],
              ),
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 28),
          ),
          if (!compact) ...[
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Songloft',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Personal music space',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final bool compact;
  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.compact,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground =
        selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant;

    return Tooltip(
      message: compact ? destination.label : '',
      child: Material(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.78)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 54,
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: selected
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.18),
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment:
                  compact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                IconTheme(
                  data: IconThemeData(
                    color: foreground,
                    size: 24,
                  ),
                  child: selected ? destination.selectedIcon : destination.icon,
                ),
                if (!compact) ...[
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        fontWeight: selected ? FontWeight.w750 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryStatus extends StatelessWidget {
  final bool compact;

  const _LibraryStatus({required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
        ),
        child: compact
            ? Icon(Icons.cloud_done_rounded, color: colorScheme.secondary)
            : Row(
                children: [
                  Icon(Icons.cloud_done_rounded, color: colorScheme.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '音乐库已连接',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '随时开始播放',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
