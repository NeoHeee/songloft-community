import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/url_helper.dart';
import '../../domain/playlist.dart';

/// 新版歌单列表项组件
class PlaylistListItem extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onPlayAll;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelect;
  final bool isCurrentPlaylist;
  final bool isPlaying;

  const PlaylistListItem({
    super.key,
    required this.playlist,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleVisibility,
    this.onPlayAll,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
    this.isCurrentPlaylist = false,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final highlighted = (isSelectionMode && isSelected) || isCurrentPlaylist;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color:
            highlighted
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isSelectionMode ? onSelect : onTap,
          onLongPress: isSelectionMode ? null : onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    highlighted
                        ? colorScheme.primary.withValues(alpha: 0.55)
                        : colorScheme.outlineVariant.withValues(alpha: 0.22),
                width: highlighted ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                if (isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onSelect?.call(),
                  ),
                  const SizedBox(width: 4),
                ],
                _Cover(
                  playlist: playlist,
                  isCurrentPlaylist: isCurrentPlaylist,
                  isPlaying: isPlaying,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              playlist.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color:
                                    isCurrentPlaylist
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (playlist.type == 'radio') ...[
                            const SizedBox(width: 8),
                            _TypeBadge(
                              icon: Icons.radio_rounded,
                              label: '电台',
                              background: colorScheme.tertiaryContainer,
                              foreground: colorScheme.onTertiaryContainer,
                            ),
                          ],
                          if (playlist.isHidden) ...[
                            const SizedBox(width: 6),
                            _TypeBadge(
                              icon: Icons.visibility_off_rounded,
                              label: '隐藏',
                              background: colorScheme.errorContainer,
                              foreground: colorScheme.onErrorContainer,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (playlist.labels.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children:
                              playlist.labels
                                  .take(3)
                                  .map((label) => _LabelChip(label: label))
                                  .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isSelectionMode) ...[
                  if (onPlayAll != null)
                    _RoundActionButton(
                      tooltip: '播放全部',
                      icon:
                          isCurrentPlaylist && isPlaying
                              ? Icons.equalizer_rounded
                              : Icons.play_arrow_rounded,
                      selected: isCurrentPlaylist,
                      onPressed: onPlayAll,
                    ),
                  const SizedBox(width: 4),
                  _buildMoreButton(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    final parts = <String>['${playlist.songCount} 首歌曲'];
    if (playlist.description?.isNotEmpty == true) {
      parts.add(playlist.description!);
    }
    return parts.join(' · ');
  }

  Widget _buildMoreButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded),
      tooltip: '更多操作',
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'toggle_visibility':
            onToggleVisibility?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder:
          (context) => [
            if (onEdit != null)
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_rounded),
                  title: Text('编辑'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            if (onToggleVisibility != null && !playlist.isBuiltIn)
              PopupMenuItem(
                value: 'toggle_visibility',
                child: ListTile(
                  leading: Icon(
                    playlist.isHidden
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  title: Text(playlist.isHidden ? '取消隐藏' : '隐藏歌单'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            if (onDelete != null && !playlist.isBuiltIn)
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: colorScheme.error,
                  ),
                  title: Text('删除', style: TextStyle(color: colorScheme.error)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
    );
  }
}

class _Cover extends StatelessWidget {
  final Playlist playlist;
  final bool isCurrentPlaylist;
  final bool isPlaying;

  const _Cover({
    required this.playlist,
    required this.isCurrentPlaylist,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (playlist.coverImageUrl != null)
            ExcludeSemantics(
              child: CachedNetworkImage(
                imageUrl: UrlHelper.buildCoverUrl(playlist.coverImageUrl!),
                fit: BoxFit.cover,
                placeholder:
                    (_, _) =>
                        _CoverPlaceholder(isRadio: playlist.type == 'radio'),
                errorWidget:
                    (_, _, _) =>
                        _CoverPlaceholder(isRadio: playlist.type == 'radio'),
              ),
            )
          else
            _CoverPlaceholder(isRadio: playlist.type == 'radio'),
          if (isCurrentPlaylist && isPlaying)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: Icon(
                Icons.equalizer_rounded,
                size: 27,
                color: colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final bool isRadio;

  const _CoverPlaceholder({required this.isRadio});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primaryContainer, colorScheme.tertiaryContainer],
        ),
      ),
      child: Icon(
        isRadio ? Icons.radio_rounded : Icons.graphic_eq_rounded,
        size: 30,
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.72),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;

  const _RoundActionButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor:
            selected
                ? colorScheme.primary
                : colorScheme.primaryContainer.withValues(alpha: 0.62),
        foregroundColor: selected ? colorScheme.onPrimary : colorScheme.primary,
      ),
      icon: Icon(icon),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  const _TypeBadge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String label;

  const _LabelChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayLabel = switch (label) {
      'built_in' => '内置',
      'auto_created' => '自动',
      'hidden' => '已隐藏',
      _ => label,
    };
    final background = switch (label) {
      'built_in' => colorScheme.primaryContainer,
      'auto_created' => colorScheme.secondaryContainer,
      'hidden' => colorScheme.errorContainer,
      _ => colorScheme.tertiaryContainer,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
