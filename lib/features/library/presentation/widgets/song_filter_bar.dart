import 'package:flutter/material.dart';

import '../../../../config/constants.dart';

/// 歌曲类型筛选栏
class SongFilterBar extends StatelessWidget {
  final String? currentType;
  final ValueChanged<String?> onTypeChanged;
  final int songCount;

  const SongFilterBar({
    super.key,
    this.currentType,
    required this.onTypeChanged,
    this.songCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      icon: Icons.apps_rounded,
                      label: '全部',
                      isSelected: currentType == null,
                      onTap: () => onTypeChanged(null),
                    ),
                    _FilterChip(
                      icon: Icons.storage_rounded,
                      label: '本地',
                      isSelected: currentType == AppConstants.songTypeLocal,
                      onTap: () => onTypeChanged(AppConstants.songTypeLocal),
                    ),
                    _FilterChip(
                      icon: Icons.cloud_rounded,
                      label: '网络',
                      isSelected: currentType == AppConstants.songTypeRemote,
                      onTap: () => onTypeChanged(AppConstants.songTypeRemote),
                    ),
                    _FilterChip(
                      icon: Icons.radio_rounded,
                      label: '电台',
                      isSelected: currentType == AppConstants.songTypeRadio,
                      onTap: () => onTypeChanged(AppConstants.songTypeRadio),
                    ),
                  ],
                ),
              ),
            ),
            if (songCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  '$songCount 首',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
