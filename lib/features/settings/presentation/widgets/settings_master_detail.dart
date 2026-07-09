import 'package:flutter/material.dart';

import '../../../../core/theme/responsive.dart';

class SettingsCategory {
  final IconData icon;
  final String title;
  final String subtitle;

  const SettingsCategory({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

/// 设置页主从布局：移动端使用入口卡片，桌面端使用分类侧栏。
class SettingsMasterDetail extends StatelessWidget {
  final List<SettingsCategory> categories;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;
  final IndexedWidgetBuilder contentBuilder;
  final Widget? header;

  const SettingsMasterDetail({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
    required this.contentBuilder,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isWideScreen && !context.isTv && !context.isAuto) {
      return _buildWideLayout(context);
    }
    return _buildMobileLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
      children: [
        if (header != null) ...[
          header!,
          const SizedBox(height: 16),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
          child: Text(
            '设置分类',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (var index = 0; index < categories.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onCategorySelected(index),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Row(
                    children: [
                      _CategoryIcon(
                        icon: categories[index].icon,
                        selected: false,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categories[index].title,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              categories[index].subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 300,
          margin: const EdgeInsets.fromLTRB(14, 12, 8, 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (header != null) ...[
                header!,
                const SizedBox(height: 14),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                child: Text(
                  '偏好设置',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              for (var index = 0; index < categories.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _CategoryItem(
                    category: categories[index],
                    selected: index == selectedIndex,
                    onTap: () => onCategorySelected(index),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 14, 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ColoredBox(
                color: colorScheme.surface.withValues(alpha: 0.42),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: contentBuilder(context, selectedIndex),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final SettingsCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Material(
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.72)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: selected
                ? Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.18),
                  )
                : null,
          ),
          child: Row(
            children: [
              _CategoryIcon(icon: category.icon, selected: selected),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: selected
                            ? colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.68,
                              )
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;

  const _CategoryIcon({required this.icon, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.14)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        icon,
        size: 22,
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
    );
  }
}
