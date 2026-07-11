import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_config.dart';
import '../../../../config/constants.dart';
import '../../../../core/theme/responsive.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../shared/models/song.dart';
import '../../../../shared/widgets/favorite_button.dart';
import '../../../../shared/widgets/tv_focusable.dart';

/// 歌曲列表项组件
class SongListTile extends ConsumerWidget {
  final Song song;
  final int index;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isNarrow;
  final bool isCurrentSong;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelect;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onAddToPlaylist;

  const SongListTile({
    super.key,
    required this.song,
    required this.index,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.isNarrow = false,
    this.isCurrentSong = false,
    this.onTap,
    this.onLongPress,
    this.onSelect,
    this.onDelete,
    this.onEdit,
    this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        if (context.isMobile ||
            constraints.maxWidth < ResponsiveBreakpoints.tablet) {
          return _buildMobileLayout(context);
        }
        return _buildDesktopLayout(context);
      },
    );

    if (!AppConfig.isTvMode) return content;
    final action = isSelectionMode ? onSelect : onTap;
    return TvFocusable(
      autofocus: index == 0,
      onSelect: action,
      enabled: action != null,
      focusedScale: 1.015,
      borderRadius: 18,
      child: ExcludeFocus(child: content),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color:
            isCurrentSong
                ? colorScheme.primaryContainer.withValues(alpha: 0.62)
                : colorScheme.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isSelectionMode ? onSelect : onTap,
          onLongPress: isSelectionMode ? null : onLongPress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Row(
              children: [
                if (isSelectionMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onSelect?.call(),
                  )
                else
                  _buildCoverImage(song.coverUrl, 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isCurrentSong) ...[
                            Icon(
                              Icons.equalizer_rounded,
                              size: 17,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    isCurrentSong
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              song.artist ?? '未知艺术家',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            Formatters.formatDuration(song.duration),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildTrailingActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Material(
        color:
            isCurrentSong
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isSelectionMode ? onSelect : onTap,
          onLongPress: isSelectionMode ? null : onLongPress,
          hoverColor: colorScheme.surfaceContainerHigh.withValues(alpha: 0.78),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border:
                  isCurrentSong
                      ? Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.18),
                      )
                      : null,
            ),
            child: Row(
              children: [
                if (isSelectionMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onSelect?.call(),
                  )
                else
                  SizedBox(
                    width: 40,
                    child:
                        isCurrentSong
                            ? Icon(
                              Icons.equalizer_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            )
                            : Text(
                              '${index + 1}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                  ),
                const SizedBox(width: 10),
                _buildCoverImage(song.coverUrl, 44),
                const SizedBox(width: 13),
                Expanded(
                  flex: 3,
                  child: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isCurrentSong ? colorScheme.primary : null,
                      fontWeight:
                          isCurrentSong ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Text(
                    song.artist ?? '未知艺术家',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 16),
                if (!isNarrow) ...[
                  Expanded(
                    flex: 2,
                    child: Text(
                      song.album ?? '未知专辑',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                SizedBox(width: 60, child: _buildTypeChip(context)),
                const SizedBox(width: 16),
                SizedBox(
                  width: 60,
                  child: Text(
                    Formatters.formatDuration(song.duration),
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 140, child: _buildDesktopActions(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(String? coverUrl, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size > 48 ? 15 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child:
          coverUrl != null
              ? ExcludeSemantics(
                child: Image.network(
                  UrlHelper.buildCoverUrl(coverUrl),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildDefaultCover(size),
                ),
              )
              : _buildDefaultCover(size),
    );
  }

  Widget _buildDefaultCover(double size) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.tertiaryContainer,
              ],
            ),
          ),
          child: Icon(
            _getTypeIcon(),
            size: size * 0.48,
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.72),
          ),
        );
      },
    );
  }

  IconData _getTypeIcon() {
    switch (song.type) {
      case AppConstants.songTypeRadio:
        return Icons.radio_rounded;
      case AppConstants.songTypeRemote:
        return Icons.cloud_rounded;
      default:
        return Icons.graphic_eq_rounded;
    }
  }

  Widget _buildTypeChip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    late final String label;
    late final Color color;

    switch (song.type) {
      case AppConstants.songTypeRadio:
        label = '电台';
        color = colorScheme.tertiary;
        break;
      case AppConstants.songTypeRemote:
        label = '网络';
        color = colorScheme.secondary;
        break;
      default:
        label = '本地';
        color = colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTrailingActions(BuildContext context) {
    if (isSelectionMode) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FavoriteButton(songId: song.id, songType: song.type, size: 20),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (value) {
            switch (value) {
              case 'play':
                onTap?.call();
                break;
              case 'edit':
                onEdit?.call();
                break;
              case 'add_to_playlist':
                onAddToPlaylist?.call();
                break;
              case 'delete':
                onDelete?.call();
                break;
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'play',
                  child: ListTile(
                    leading: Icon(Icons.play_arrow_rounded),
                    title: Text('播放'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (song.type != AppConstants.songTypeLocal)
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_rounded),
                      title: Text('编辑'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'add_to_playlist',
                  child: ListTile(
                    leading: Icon(Icons.playlist_add_rounded),
                    title: Text('添加到歌单'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline_rounded),
                    title: Text('删除'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildDesktopActions(BuildContext context) {
    if (isSelectionMode) return const SizedBox(width: 140);

    const constraints = BoxConstraints(minWidth: 28, minHeight: 28);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.play_arrow_rounded),
          tooltip: '播放',
          onPressed: onTap,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: constraints,
        ),
        FavoriteButton(songId: song.id, songType: song.type, size: 20),
        if (song.type != AppConstants.songTypeLocal)
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: '编辑',
            onPressed: onEdit,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: constraints,
          ),
        IconButton(
          icon: const Icon(Icons.playlist_add_rounded),
          tooltip: '添加到歌单',
          onPressed: onAddToPlaylist,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: constraints,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: '删除',
          onPressed: onDelete,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: constraints,
        ),
      ],
    );
  }
}
