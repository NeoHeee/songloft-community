import 'package:flutter/material.dart';

class LibraryActionsSheet extends StatelessWidget {
  final String currentSort;
  final bool showHidden;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onAddRemote;
  final VoidCallback onAddRadio;
  final VoidCallback onToggleHidden;
  final VoidCallback onClean;

  const LibraryActionsSheet({
    super.key,
    required this.currentSort,
    required this.showHidden,
    required this.onSortChanged,
    required this.onAddRemote,
    required this.onAddRadio,
    required this.onToggleHidden,
    required this.onClean,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentSort,
    required bool showHidden,
    required ValueChanged<String> onSortChanged,
    required VoidCallback onAddRemote,
    required VoidCallback onAddRadio,
    required VoidCallback onToggleHidden,
    required VoidCallback onClean,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => LibraryActionsSheet(
        currentSort: currentSort,
        showHidden: showHidden,
        onSortChanged: onSortChanged,
        onAddRemote: onAddRemote,
        onAddRadio: onAddRadio,
        onToggleHidden: onToggleHidden,
        onClean: onClean,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '歌曲库操作',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '排序、添加和维护歌曲库',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text('排序方式', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SortChip(
                value: 'added_at',
                label: '最近加入',
                icon: Icons.schedule_rounded,
                currentSort: currentSort,
                onSelected: onSortChanged,
              ),
              _SortChip(
                value: 'file_modified_at',
                label: '文件时间',
                icon: Icons.insert_drive_file_outlined,
                currentSort: currentSort,
                onSelected: onSortChanged,
              ),
              _SortChip(
                value: 'title',
                label: '标题',
                icon: Icons.sort_by_alpha_rounded,
                currentSort: currentSort,
                onSelected: onSortChanged,
              ),
              _SortChip(
                value: 'artist',
                label: '艺术家',
                icon: Icons.person_rounded,
                currentSort: currentSort,
                onSelected: onSortChanged,
              ),
              _SortChip(
                value: 'duration',
                label: '时长',
                icon: Icons.timer_outlined,
                currentSort: currentSort,
                onSelected: onSortChanged,
              ),
            ],
          ),
          const SizedBox(height: 22),
          _ActionTile(
            icon: Icons.cloud_rounded,
            title: '添加网络歌曲',
            subtitle: '添加一个可在线播放的音源地址',
            onTap: onAddRemote,
          ),
          _ActionTile(
            icon: Icons.radio_rounded,
            title: '添加电台',
            subtitle: '添加直播流或网络电台地址',
            onTap: onAddRadio,
          ),
          _ActionTile(
            icon: showHidden
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            title: showHidden ? '隐藏已隐藏歌曲' : '显示隐藏歌曲',
            subtitle: showHidden ? '恢复默认歌曲库视图' : '临时显示被隐藏歌单中的歌曲',
            onTap: onToggleHidden,
          ),
          _ActionTile(
            icon: Icons.cleaning_services_rounded,
            title: '清理无效记录',
            subtitle: '清理文件已不存在的本地歌曲记录',
            isDestructive: true,
            onTap: onClean,
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final String currentSort;
  final ValueChanged<String> onSelected;

  const _SortChip({
    required this.value,
    required this.label,
    required this.icon,
    required this.currentSort,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == currentSort;
    return FilterChip(
      selected: selected,
      showCheckmark: true,
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onSelected: (_) {
        Navigator.of(context).pop();
        onSelected(value);
      },
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isDestructive
        ? colorScheme.error
        : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDestructive
            ? colorScheme.errorContainer.withValues(alpha: 0.42)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            onTap();
          },
          borderRadius: BorderRadius.circular(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDestructive
                          ? colorScheme.errorContainer
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: isDestructive
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
        ),
      ),
    );
  }
}
