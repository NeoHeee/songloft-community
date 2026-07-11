import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_config.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../shared/models/song.dart';
import '../../../../shared/utils/responsive_snackbar.dart';
import '../../../../shared/widgets/tv_action_dialog.dart';
import '../../../../shared/widgets/tv_focusable.dart';
import '../providers/player_provider.dart';

/// 播放队列侧边栏。
///
/// TV 端会自动滚动到当前歌曲，并支持方向键、确认键和菜单键操作。
class PlaylistDrawer extends ConsumerStatefulWidget {
  const PlaylistDrawer({super.key});

  @override
  ConsumerState<PlaylistDrawer> createState() => _PlaylistDrawerState();
}

class _PlaylistDrawerState extends ConsumerState<PlaylistDrawer> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final currentIndex = ref.read(playerStateProvider).currentIndex;
    final initialOffset =
        currentIndex > 0
            ? (currentIndex * 76.0 - 120).clamp(0.0, double.infinity).toDouble()
            : 0.0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerStateProvider);
    final notifier = ref.read(playerStateProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTv = AppConfig.isTvMode;
    final drawerWidth =
        isTv
            ? (MediaQuery.sizeOf(context).width * 0.38)
                .clamp(420.0, 560.0)
                .toDouble()
            : 320.0;

    return Container(
      width: drawerWidth,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          left: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: SafeArea(
        left: false,
        child: Column(
          children: [
            _buildHeader(context, state, notifier, theme, colorScheme),
            const Divider(height: 1),
            Expanded(
              child:
                  state.playlist.isEmpty
                      ? _buildEmptyState(context, colorScheme, theme)
                      : _buildQueueList(context, state, notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    dynamic state,
    PlayerNotifier notifier,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isTv = AppConfig.isTvMode;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTv ? 18 : 12,
        vertical: isTv ? 14 : 8,
      ),
      child: Row(
        children: [
          Text(
            '播放队列',
            style: (isTv
                    ? theme.textTheme.titleLarge
                    : theme.textTheme.titleSmall)
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${state.playlist.length}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const Spacer(),
          if (state.playlist.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, size: isTv ? 26 : 18),
              tooltip: '清空播放列表',
              onPressed: () => _showClearConfirmation(context, notifier),
            ),
          IconButton(
            autofocus: isTv && state.playlist.isEmpty,
            icon: Icon(Icons.close_rounded, size: isTv ? 28 : 18),
            tooltip: '关闭播放队列',
            onPressed: notifier.closePlaylistDrawer,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: AppConfig.isTvMode ? 72 : 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            '播放队列为空',
            style: (AppConfig.isTvMode
                    ? theme.textTheme.titleLarge
                    : theme.textTheme.bodyMedium)
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            '从歌曲菜单中选择“加入播放队列”',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(
    BuildContext context,
    dynamic state,
    PlayerNotifier notifier,
  ) {
    if (AppConfig.isTvMode) {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        itemCount: state.playlist.length,
        itemBuilder: (context, index) {
          final song = state.playlist[index] as Song;
          final isCurrentSong = index == state.currentIndex;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _DrawerSongItem(
              key: ValueKey('tv_drawer_${song.id}_${song.type}_$index'),
              song: song,
              index: index,
              isCurrentSong: isCurrentSong,
              isPlaying: isCurrentSong && state.isPlaying,
              autofocus: isCurrentSong,
              onTap:
                  () => notifier.playPlaylist(
                    List<Song>.from(state.playlist),
                    startIndex: index,
                  ),
              onRemove: () => _removeSong(context, notifier, index, song),
              onShowActions:
                  () => _showQueueItemActions(
                    context,
                    notifier,
                    state.playlist.length,
                    index,
                    song,
                  ),
            ),
          );
        },
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: state.playlist.length,
      onReorder: notifier.reorderPlaylist,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final song = state.playlist[index] as Song;
        final isCurrentSong = index == state.currentIndex;
        return _DrawerSongItem(
          key: ValueKey('drawer_${song.id}_${song.type}_$index'),
          song: song,
          index: index,
          isCurrentSong: isCurrentSong,
          isPlaying: isCurrentSong && state.isPlaying,
          onTap:
              () => notifier.playPlaylist(
                List<Song>.from(state.playlist),
                startIndex: index,
              ),
          onRemove: () => _removeSong(context, notifier, index, song),
          onShowActions:
              () => _showQueueItemActions(
                context,
                notifier,
                state.playlist.length,
                index,
                song,
              ),
        );
      },
    );
  }

  void _showQueueItemActions(
    BuildContext context,
    PlayerNotifier notifier,
    int itemCount,
    int index,
    Song song,
  ) {
    showTvActionDialog(
      context: context,
      title: song.title,
      actions: [
        TvActionItem(
          icon: Icons.play_arrow_rounded,
          label: '立即播放',
          onPressed:
              () => notifier.playPlaylist(
                List<Song>.from(ref.read(playerStateProvider).playlist),
                startIndex: index,
              ),
        ),
        if (index > 0)
          TvActionItem(
            icon: Icons.arrow_upward_rounded,
            label: '向前移动',
            onPressed: () => notifier.reorderPlaylist(index, index - 1),
          ),
        if (index < itemCount - 1)
          TvActionItem(
            icon: Icons.arrow_downward_rounded,
            label: '向后移动',
            onPressed: () => notifier.reorderPlaylist(index, index + 2),
          ),
        TvActionItem(
          icon: Icons.remove_circle_outline_rounded,
          label: '从播放队列移除',
          onPressed: () => _removeSong(context, notifier, index, song),
          destructive: true,
        ),
      ],
    );
  }

  void _removeSong(
    BuildContext context,
    PlayerNotifier notifier,
    int index,
    Song song,
  ) {
    notifier.removeFromPlaylist(index);
    ResponsiveSnackBar.show(
      context,
      message: '已移除「${song.title}」',
      duration: const Duration(seconds: 2),
    );
  }

  void _showClearConfirmation(BuildContext context, PlayerNotifier notifier) {
    if (AppConfig.isTvMode) {
      showTvActionDialog(
        context: context,
        title: '清空播放队列？',
        actions: [
          TvActionItem(
            icon: Icons.arrow_back_rounded,
            label: '取消',
            onPressed: () {},
          ),
          TvActionItem(
            icon: Icons.delete_forever_rounded,
            label: '确认清空',
            onPressed: notifier.clearPlaylist,
            destructive: true,
          ),
        ],
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('清空播放队列'),
            content: const Text('确定要清空播放队列吗？'),
            actions: [
              TextButton(
                autofocus: true,
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  notifier.clearPlaylist();
                  Navigator.pop(dialogContext);
                },
                child: const Text('清空'),
              ),
            ],
          ),
    );
  }
}

class _DrawerSongItem extends StatelessWidget {
  final Song song;
  final int index;
  final bool isCurrentSong;
  final bool isPlaying;
  final bool autofocus;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onShowActions;

  const _DrawerSongItem({
    super.key,
    required this.song,
    required this.index,
    required this.isCurrentSong,
    required this.isPlaying,
    required this.onTap,
    required this.onRemove,
    required this.onShowActions,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (AppConfig.isTvMode) {
      return TvFocusable(
        autofocus: autofocus,
        onSelect: onTap,
        onLongSelect: onShowActions,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.contextMenu ||
              key == LogicalKeyboardKey.gameButtonY ||
              key == LogicalKeyboardKey.keyM ||
              key == LogicalKeyboardKey.delete ||
              key == LogicalKeyboardKey.arrowRight) {
            onShowActions();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        focusedScale: 1.015,
        borderRadius: 16,
        child: ExcludeFocus(child: content),
      );
    }

    return Dismissible(
      key: ValueKey('dismiss_drawer_${song.id}_${song.type}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(
          Icons.delete_rounded,
          color: Theme.of(context).colorScheme.onErrorContainer,
          size: 18,
        ),
      ),
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isTv = AppConfig.isTvMode;
    final coverSize = isTv ? 52.0 : 36.0;

    return Material(
      color:
          isCurrentSong
              ? colorScheme.primaryContainer.withValues(alpha: isTv ? 0.5 : 0.3)
              : Colors.transparent,
      borderRadius: BorderRadius.circular(isTv ? 16 : 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isTv ? 16 : 0),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTv ? 12 : 4,
            vertical: isTv ? 9 : 6,
          ),
          child: Row(
            children: [
              if (!isTv)
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Container(
                width: coverSize,
                height: coverSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isTv ? 10 : 4),
                  color: colorScheme.surfaceContainerHighest,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    if (song.coverUrl != null)
                      ExcludeSemantics(
                        child: CachedNetworkImage(
                          imageUrl: UrlHelper.buildCoverUrl(song.coverUrl!),
                          fit: BoxFit.cover,
                          width: coverSize,
                          height: coverSize,
                          placeholder:
                              (_, _) =>
                                  _buildCoverPlaceholder(colorScheme, isTv),
                          errorWidget:
                              (_, _, _) =>
                                  _buildCoverPlaceholder(colorScheme, isTv),
                        ),
                      )
                    else
                      _buildCoverPlaceholder(colorScheme, isTv),
                    if (isPlaying)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Icon(
                            Icons.equalizer_rounded,
                            size: isTv ? 26 : 18,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: isTv ? 14 : 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      style: (isTv
                              ? textTheme.titleMedium
                              : textTheme.bodySmall)
                          ?.copyWith(
                            fontWeight:
                                isCurrentSong
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                            color:
                                isCurrentSong
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist ?? '未知艺术家',
                      style: (isTv
                              ? textTheme.bodyMedium
                              : textTheme.labelSmall)
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.formatDuration(song.duration),
                style: (isTv ? textTheme.bodyMedium : textTheme.labelSmall)
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              if (isTv) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.more_vert_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ] else
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded),
                  iconSize: 16,
                  tooltip: '从播放列表移除',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                    minimumSize: const Size(28, 28),
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder(ColorScheme colorScheme, bool isTv) {
    return Center(
      child: Icon(
        Icons.music_note_rounded,
        size: isTv ? 25 : 18,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }
}
