import 'dart:async';
import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/responsive.dart';
import '../../../core/utils/color_extraction.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/url_helper.dart';
import '../../../shared/models/song.dart';
import '../../../shared/utils/responsive_snackbar.dart';
import '../../../shared/widgets/delete_song_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/song_picker_modal.dart';
import '../../library/presentation/providers/songs_provider.dart';
import '../../player/presentation/providers/player_provider.dart';
import '../domain/playlist.dart';
import 'providers/playlist_provider.dart';
import 'widgets/song_cover_picker_modal.dart';

/// 新版歌单详情页面。
class PlaylistDetailPage extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends ConsumerState<PlaylistDetailPage> {
  int get _playlistIdInt => int.tryParse(widget.playlistId) ?? 0;

  static const double _loadMoreThreshold = 300;

  late final ScrollController _scrollController;
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isSortMode = false;
  bool _isSelectMode = false;
  final Set<int> _selectedSongIds = {};
  List<Song> _sortableSongs = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlistAsync = ref.watch(playlistDetailProvider(_playlistIdInt));
    final songsAsync = ref.watch(playlistSongsProvider(_playlistIdInt));

    return BackButtonListener(
      onBackButtonPressed: _handleBackButton,
      child: playlistAsync.when(
        data: (playlist) => Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(playlist.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: '返回',
              onPressed: _handleBack,
            ),
            actions: _buildAppBarActions(playlist, songsAsync),
          ),
          body: _buildContent(context, playlist, songsAsync),
        ),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: _handleBack,
            ),
            title: const Text('歌单详情'),
          ),
          body: _buildError(error.toString()),
        ),
      ),
    );
  }

  Future<bool> _handleBackButton() async {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
      return true;
    }
    if (_isSortMode) {
      _cancelSortMode();
      return true;
    }
    if (_isSelectMode) {
      _exitSelectMode();
      return true;
    }
    return false;
  }

  Future<void> _handleBack() async {
    if (await _handleBackButton()) return;
    _goBack();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/playlists');
    }
  }

  Widget _buildContent(
    BuildContext context,
    Playlist playlist,
    AsyncValue<PaginatedSongsState> songsAsync,
  ) {
    final useWideLayout =
        (context.isDesktop || context.isTv) && !context.isAuto;
    if (useWideLayout) {
      return _buildWideContent(context, playlist, songsAsync);
    }
    return _buildNarrowContent(context, playlist, songsAsync);
  }

  Widget _buildWideContent(
    BuildContext context,
    Playlist playlist,
    AsyncValue<PaginatedSongsState> songsAsync,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 326,
            child: _buildPlaylistPanel(
              context,
              playlist,
              songsAsync,
              vertical: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.22),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildWorkspaceHeader(
                        context,
                        playlist,
                        songsAsync,
                        showPrimaryActions: false,
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildSearchBar(context)),
                    _buildSongSliver(context, playlist, songsAsync),
                    if (songsAsync.value != null)
                      SliverToBoxAdapter(
                        child: _buildLoadMoreIndicator(songsAsync.value!),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.paddingOf(context).bottom + 90,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowContent(
    BuildContext context,
    Playlist playlist,
    AsyncValue<PaginatedSongsState> songsAsync,
  ) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: _buildPlaylistPanel(
                context,
                playlist,
                songsAsync,
                vertical: false,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildWorkspaceHeader(
              context,
              playlist,
              songsAsync,
              showPrimaryActions: true,
            ),
          ),
          SliverToBoxAdapter(child: _buildSearchBar(context)),
          _buildSongSliver(context, playlist, songsAsync),
          if (songsAsync.value != null)
            SliverToBoxAdapter(
              child: _buildLoadMoreIndicator(songsAsync.value!),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 90),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistPanel(
    BuildContext context,
    Playlist playlist,
    AsyncValue<PaginatedSongsState> songsAsync, {
    required bool vertical,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = songsAsync.value;
    final songCount = state?.total ?? 0;
    final palette = ref.watch(coverColorsProvider(playlist.coverUrl)).value;
    final accent = palette?.vibrantColor ?? colorScheme.primary;
    final background = palette?.darkMutedColor ?? colorScheme.primaryContainer;
    final tags = <String>[
      if (playlist.type == 'radio') '电台',
      ...playlist.labels.map(_getLabelName),
      '$songCount 首歌曲',
    ];

    final cover = _PlaylistCover(
      playlist: playlist,
      size: vertical ? 252 : 150,
      accent: accent,
    );

    final details = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: vertical
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          playlist.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: vertical ? TextAlign.center : TextAlign.left,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        if (playlist.description?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(
            playlist.description!,
            maxLines: vertical ? 4 : 2,
            overflow: TextOverflow.ellipsis,
            textAlign: vertical ? TextAlign.center : TextAlign.left,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: vertical ? WrapAlignment.center : WrapAlignment.start,
          children: [for (final tag in tags) _PlaylistMetaChip(label: tag)],
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(vertical ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            background.withValues(alpha: 0.38),
            colorScheme.surfaceContainerLow.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: vertical
          ? SingleChildScrollView(
              child: Column(
                children: [
                  cover,
                  const SizedBox(height: 20),
                  details,
                  const SizedBox(height: 20),
                  _buildPrimaryActions(playlist, state?.items ?? []),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                if (compact) {
                  return Column(
                    children: [
                      cover,
                      const SizedBox(height: 16),
                      Align(alignment: Alignment.centerLeft, child: details),
                    ],
                  );
                }
                return Row(
                  children: [
                    cover,
                    const SizedBox(width: 18),
                    Expanded(child: details),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildWorkspaceHeader(
    BuildContext context,
    Playlist playlist,
    AsyncValue<PaginatedSongsState> songsAsync, {
    required bool showPrimaryActions,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = songsAsync.value;
    final songs = state?.items ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;
            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (showPrimaryActions && !_isSortMode && !_isSelectMode) ...[
                  FilledButton.icon(
                    onPressed: songs.isEmpty
                        ? null
                        : () => _playAll(playlist, songs),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('播放全部'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _addSongs,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('添加歌曲'),
                  ),
                ],
                if (!_isSortMode && !_isSelectMode)
                  _buildSortButton(state, songs),
                if (!_isSortMode && !_isSelectMode && songs.isNotEmpty)
                  IconButton.filledTonal(
                    onPressed: _enterSelectMode,
                    icon: const Icon(Icons.checklist_rounded),
                    tooltip: '多选歌曲',
                  ),
              ],
            );

            final title = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSortMode
                      ? '调整歌曲顺序'
                      : _isSelectMode
                      ? '已选择 ${_selectedSongIds.length} 首'
                      : '歌曲列表',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state == null
                      ? '正在读取歌单内容'
                      : state.keyword.isEmpty
                      ? '共 ${state.total} 首，可搜索、排序或批量管理'
                      : '搜索“${state.keyword}”，找到 ${state.total} 首',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  if (actions.children.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    actions,
                  ],
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: title),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPrimaryActions(Playlist playlist, List<Song> songs) {
    if (_isSortMode || _isSelectMode) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: songs.isEmpty ? null : () => _playAll(playlist, songs),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('播放全部'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 9),
        OutlinedButton.icon(
          onPressed: _addSongs,
          icon: const Icon(Icons.add_rounded),
          label: const Text('添加歌曲'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Widget _buildSortButton(PaginatedSongsState? state, List<Song> songs) {
    if ((state?.total ?? songs.length) <= 1) {
      return const SizedBox.shrink();
    }

    final currentSort = state?.sort ?? 'position';
    final hasKeyword = state?.keyword.isNotEmpty == true;

    return PopupMenuButton<String>(
      tooltip: '排序',
      icon: const Icon(Icons.swap_vert_rounded),
      onSelected: (value) {
        final notifier = ref.read(
          playlistSongsProvider(_playlistIdInt).notifier,
        );
        switch (value) {
          case 'view_position':
            notifier.setSort('position', 'asc');
          case 'view_added_at':
            notifier.setSort('added_at', 'desc');
          case 'view_file_modified_at':
            notifier.setSort('file_modified_at', 'desc');
          case 'view_title':
            notifier.setSort('title', 'asc');
          case 'view_artist':
            notifier.setSort('artist', 'asc');
          case 'view_duration':
            notifier.setSort('duration', 'asc');
          case 'perm_name_asc':
            _autoSortByName(songs, ascending: true);
          case 'perm_name_desc':
            _autoSortByName(songs, ascending: false);
          case 'perm_number':
            _autoSortByNumberPrefix(songs);
          case 'manual':
            _enterSortMode(songs);
        }
      },
      itemBuilder: (context) => [
        _buildSortMenuItem(
          value: 'view_position',
          icon: Icons.reorder_rounded,
          title: '歌单顺序',
          selected: currentSort == 'position',
        ),
        _buildSortMenuItem(
          value: 'view_added_at',
          icon: Icons.schedule_rounded,
          title: '最近加入',
          selected: currentSort == 'added_at',
        ),
        _buildSortMenuItem(
          value: 'view_file_modified_at',
          icon: Icons.insert_drive_file_outlined,
          title: '文件时间',
          selected: currentSort == 'file_modified_at',
        ),
        _buildSortMenuItem(
          value: 'view_title',
          icon: Icons.sort_by_alpha_rounded,
          title: '标题',
          selected: currentSort == 'title',
        ),
        _buildSortMenuItem(
          value: 'view_artist',
          icon: Icons.person_rounded,
          title: '艺术家',
          selected: currentSort == 'artist',
        ),
        _buildSortMenuItem(
          value: 'view_duration',
          icon: Icons.timer_outlined,
          title: '时长',
          selected: currentSort == 'duration',
        ),
        if (!hasKeyword) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'perm_name_asc',
            child: ListTile(
              leading: Icon(Icons.arrow_downward_rounded),
              title: Text('永久按名称 A→Z'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'perm_name_desc',
            child: ListTile(
              leading: Icon(Icons.arrow_upward_rounded),
              title: Text('永久按名称 Z→A'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'perm_number',
            child: ListTile(
              leading: Icon(Icons.format_list_numbered_rounded),
              title: Text('永久按数字前缀'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (currentSort == 'position')
            const PopupMenuItem(
              value: 'manual',
              child: ListTile(
                leading: Icon(Icons.drag_handle_rounded),
                title: Text('手动拖拽排序'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
      ],
    );
  }

  PopupMenuItem<String> _buildSortMenuItem({
    required String value,
    required IconData icon,
    required String title,
    required bool selected,
  }) {
    final color = selected ? Theme.of(context).colorScheme.primary : null;
    return PopupMenuItem(
      value: value,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: selected ? Icon(Icons.check_rounded, color: color) : null,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索当前歌单中的歌曲、艺术家或专辑',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: '清除搜索',
                ),
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildSongSliver(
    BuildContext context,
    Playlist playlist,
    AsyncValue<PaginatedSongsState> songsAsync,
  ) {
    return songsAsync.when(
      data: (state) => _buildSongList(context, playlist, state.items),
      loading: () => SliverToBoxAdapter(
        child: Column(
          children: [
            for (var index = 0; index < 5; index++) SkeletonLoader.listTile(),
          ],
        ),
      ),
      error: (error, _) =>
          SliverToBoxAdapter(child: _buildError(error.toString())),
    );
  }

  Widget _buildSongList(
    BuildContext context,
    Playlist playlist,
    List<Song> songs,
  ) {
    if (songs.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptySongs(context));
    }

    final currentSong = ref.watch(currentSongProvider);

    if (_isSortMode) {
      return SliverToBoxAdapter(
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _sortableSongs.length,
          onReorderItem: _onReorder,
          itemBuilder: (context, index) {
            final song = _sortableSongs[index];
            return _PlaylistSongTile(
              key: ValueKey(song.id),
              song: song,
              index: index,
              displayIndex: index + 1,
              isCurrent: currentSong?.id == song.id,
              showDragHandle: true,
              onTap: () {},
            );
          },
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final song = songs[index];
          final selected = _selectedSongIds.contains(song.id);
          return _PlaylistSongTile(
            song: song,
            index: index,
            displayIndex: index + 1,
            isCurrent: currentSong?.id == song.id,
            selectionMode: _isSelectMode,
            selected: selected,
            onTap: _isSelectMode
                ? () => _toggleSongSelection(song.id)
                : () => _playSong(song, songs, index),
            onLongPress: _isSelectMode
                ? null
                : () {
                    _enterSelectMode();
                    _toggleSongSelection(song.id);
                  },
            onSelected: () => _toggleSongSelection(song.id),
            onRemove: () => _removeSong(playlist.id, song),
            onDelete: () => _deleteSongFromLibrary(song),
          );
        }, childCount: songs.length),
      ),
    );
  }

  Widget _buildEmptySongs(BuildContext context) {
    final hasKeyword = _searchController.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 38),
      child: EmptyState(
        icon: hasKeyword ? Icons.search_off_rounded : Icons.music_off_rounded,
        title: hasKeyword ? '没有找到匹配的歌曲' : '歌单暂无歌曲',
        subtitle: hasKeyword ? '换一个关键词继续搜索' : '添加一些喜欢的音乐吧',
        action: hasKeyword
            ? FilledButton.tonal(
                onPressed: _clearSearch,
                child: const Text('清除搜索'),
              )
            : FilledButton.tonalIcon(
                onPressed: _addSongs,
                icon: const Icon(Icons.add_rounded),
                label: const Text('添加歌曲'),
              ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator(PaginatedSongsState state) {
    if (_isSortMode || _isSelectMode) return const SizedBox.shrink();

    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: TextButton.icon(
            onPressed: () => ref
                .read(playlistSongsProvider(_playlistIdInt).notifier)
                .loadMore(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('加载失败，点击重试'),
          ),
        ),
      );
    }
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (!state.hasMore && state.items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            '已加载全部 ${state.total} 首歌曲',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  List<Widget> _buildAppBarActions(
    Playlist playlist,
    AsyncValue<PaginatedSongsState> songsAsync,
  ) {
    final songs = songsAsync.value?.items ?? [];
    final total = songsAsync.value?.total ?? songs.length;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isSortMode) {
      return [
        TextButton(onPressed: _cancelSortMode, child: const Text('取消')),
        FilledButton.tonal(onPressed: _exitSortMode, child: const Text('保存顺序')),
        const SizedBox(width: 8),
      ];
    }

    if (_isSelectMode) {
      return [
        TextButton(
          onPressed: () async {
            await ref
                .read(playlistSongsProvider(_playlistIdInt).notifier)
                .loadAll();
            if (!mounted) return;
            final allSongs =
                ref.read(playlistSongsProvider(_playlistIdInt)).value?.items ??
                songs;
            _toggleSelectAll(allSongs);
          },
          child: Text(_selectedSongIds.length == total ? '取消全选' : '全选'),
        ),
        PopupMenuButton<String>(
          enabled: _selectedSongIds.isNotEmpty,
          tooltip: '批量操作',
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (value) {
            if (value == 'remove') _batchRemoveSelectedSongs();
            if (value == 'delete') _batchDeleteSelectedSongsFromLibrary();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(Icons.playlist_remove_rounded),
                title: Text('从歌单移除'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                ),
                title: Text(
                  '从歌曲库删除',
                  style: TextStyle(color: colorScheme.error),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        TextButton(onPressed: _exitSelectMode, child: const Text('完成')),
      ];
    }

    return [
      PopupMenuButton<String>(
        tooltip: '歌单设置',
        icon: const Icon(Icons.more_horiz_rounded),
        onSelected: (value) {
          if (value == 'edit') _showEditDialog(playlist);
          if (value == 'delete') _confirmDelete(playlist);
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: Text(playlist.isBuiltIn ? '修改封面' : '编辑歌单'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (!playlist.isBuiltIn)
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                ),
                title: Text('删除歌单', style: TextStyle(color: colorScheme.error)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    ];
  }

  Future<void> _refresh() async {
    ref.invalidate(playlistDetailProvider(_playlistIdInt));
    ref.invalidate(playlistSongsProvider(_playlistIdInt));
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(playlistSongsProvider(_playlistIdInt).notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(playlistSongsProvider(_playlistIdInt).notifier).search(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {});
    ref.read(playlistSongsProvider(_playlistIdInt).notifier).search('');
  }

  Future<void> _enterSortMode(List<Song> songs) async {
    await ref.read(playlistSongsProvider(_playlistIdInt).notifier).loadAll();
    if (!mounted) return;
    final allSongs =
        ref.read(playlistSongsProvider(_playlistIdInt)).value?.items ?? songs;
    setState(() {
      _isSortMode = true;
      _isSelectMode = false;
      _selectedSongIds.clear();
      _sortableSongs = List.from(allSongs);
    });
  }

  Future<void> _exitSortMode() async {
    final ids = _sortableSongs.map((song) => song.id).toList();
    setState(() => _isSortMode = false);

    final success = await ref
        .read(playlistNotifierProvider.notifier)
        .reorderPlaylistSongs(_playlistIdInt, ids);
    if (!mounted) return;

    if (success) {
      await ref
          .read(playlistSongsProvider(_playlistIdInt).notifier)
          .resetFilter();
      if (!mounted) return;
      ResponsiveSnackBar.showSuccess(context, message: '歌曲顺序已保存');
    } else {
      ResponsiveSnackBar.showError(context, message: '排序保存失败');
    }
  }

  void _cancelSortMode() {
    setState(() {
      _isSortMode = false;
      _sortableSongs = [];
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _sortableSongs.removeAt(oldIndex);
      _sortableSongs.insert(newIndex, item);
    });
  }

  Future<void> _autoSortByName(
    List<Song> songs, {
    required bool ascending,
  }) async {
    await ref.read(playlistSongsProvider(_playlistIdInt).notifier).loadAll();
    if (!mounted) return;
    final allSongs =
        ref.read(playlistSongsProvider(_playlistIdInt)).value?.items ?? songs;
    final sorted = List<Song>.from(allSongs)
      ..sort((a, b) {
        final result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        return ascending ? result : -result;
      });
    await _saveAutomaticSort(
      allSongs,
      sorted,
      ascending ? '已按名称升序排列' : '已按名称降序排列',
    );
  }

  Future<void> _autoSortByNumberPrefix(List<Song> songs) async {
    await ref.read(playlistSongsProvider(_playlistIdInt).notifier).loadAll();
    if (!mounted) return;
    final allSongs =
        ref.read(playlistSongsProvider(_playlistIdInt)).value?.items ?? songs;
    final sorted = List<Song>.from(allSongs)
      ..sort((a, b) {
        final numberA = _extractFirstNumber(a.title);
        final numberB = _extractFirstNumber(b.title);
        if (numberA != null && numberB != null) {
          final result = numberA.compareTo(numberB);
          return result == 0
              ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
              : result;
        }
        if (numberA != null) return -1;
        if (numberB != null) return 1;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    await _saveAutomaticSort(allSongs, sorted, '已按数字前缀排列');
  }

  Future<void> _saveAutomaticSort(
    List<Song> original,
    List<Song> sorted,
    String successMessage,
  ) async {
    final originalIds = original.map((song) => song.id).toList();
    final sortedIds = sorted.map((song) => song.id).toList();
    if (_listEquals(originalIds, sortedIds)) {
      ResponsiveSnackBar.show(context, message: '歌曲已经是该排序顺序');
      return;
    }

    final success = await ref
        .read(playlistNotifierProvider.notifier)
        .reorderPlaylistSongs(_playlistIdInt, sortedIds);
    if (!mounted) return;
    if (success) {
      await ref
          .read(playlistSongsProvider(_playlistIdInt).notifier)
          .resetFilter();
      if (!mounted) return;
      ResponsiveSnackBar.showSuccess(context, message: successMessage);
    } else {
      ResponsiveSnackBar.showError(context, message: '排序失败');
    }
  }

  int? _extractFirstNumber(String title) {
    final match = RegExp(r'(\d+)').firstMatch(title);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  bool _listEquals(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  void _enterSelectMode() {
    setState(() {
      _isSelectMode = true;
      _isSortMode = false;
      _selectedSongIds.clear();
      _sortableSongs = [];
    });
  }

  void _exitSelectMode() {
    setState(() {
      _isSelectMode = false;
      _selectedSongIds.clear();
    });
  }

  void _toggleSongSelection(int songId) {
    setState(() {
      if (!_selectedSongIds.add(songId)) {
        _selectedSongIds.remove(songId);
      }
    });
  }

  void _toggleSelectAll(List<Song> songs) {
    setState(() {
      if (_selectedSongIds.length == songs.length) {
        _selectedSongIds.clear();
      } else {
        _selectedSongIds
          ..clear()
          ..addAll(songs.map((song) => song.id));
      }
    });
  }

  Future<void> _batchRemoveSelectedSongs() async {
    if (_selectedSongIds.isEmpty) return;
    final count = _selectedSongIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量移除'),
        content: Text('确定从歌单中移除选中的 $count 首歌曲吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(playlistNotifierProvider.notifier)
        .batchRemoveSongs(_playlistIdInt, _selectedSongIds);
    if (!mounted) return;
    if (success) {
      ResponsiveSnackBar.showSuccess(context, message: '已移除 $count 首歌曲');
      _exitSelectMode();
    } else {
      ResponsiveSnackBar.showError(context, message: '移除失败');
    }
  }

  Future<void> _showEditDialog(Playlist playlist) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _PlaylistEditDialog(playlist: playlist, playlistId: _playlistIdInt),
    );

    if (result == true && mounted) {
      ref.invalidate(coverColorsProvider(playlist.coverUrl));
      ref.invalidate(playlistDetailProvider(_playlistIdInt));
      await ref.read(playlistDetailProvider(_playlistIdInt).future);
    }
  }

  Future<void> _addSongs() async {
    await ref.read(playlistSongsProvider(_playlistIdInt).notifier).loadAll();
    if (!mounted) return;
    final currentSongs = ref.read(playlistSongsProvider(_playlistIdInt));
    final excludeIds =
        currentSongs.value?.items.map((song) => song.id).toSet() ?? <int>{};
    final playlist = ref.read(playlistDetailProvider(_playlistIdInt)).value;
    final isRadio = playlist?.type == 'radio';

    final selectedIds = await SongPickerModal.show(
      context,
      excludeIds: excludeIds,
      songType: isRadio ? 'radio' : null,
      excludeType: isRadio ? null : 'radio',
    );
    if (selectedIds == null || selectedIds.isEmpty || !mounted) return;

    final result = await ref
        .read(playlistNotifierProvider.notifier)
        .addSongsToPlaylist(_playlistIdInt, selectedIds);
    if (!mounted) return;
    if (result == null) {
      ResponsiveSnackBar.showError(context, message: '添加歌曲失败');
      return;
    }
    final message = result.skipped > 0
        ? '已添加 ${result.added} 首，跳过 ${result.skipped} 首'
        : '已添加 ${result.added} 首歌曲';
    ResponsiveSnackBar.showSuccess(context, message: message);
  }

  Future<void> _confirmDelete(Playlist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除歌单'),
        content: Text('确定删除“${playlist.name}”吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(playlistNotifierProvider.notifier)
        .deletePlaylist(playlist.id);
    if (success && mounted) {
      _goBack();
      ResponsiveSnackBar.showSuccess(context, message: '歌单已删除');
    }
  }

  Future<void> _playAll(Playlist playlist, List<Song> songs) async {
    if (songs.isEmpty) {
      ResponsiveSnackBar.show(context, message: '歌单为空');
      return;
    }
    final total = await ref
        .read(playerStateProvider.notifier)
        .playPlaylistById(playlist.id);
    if (!mounted) return;
    if (total < 0) {
      ResponsiveSnackBar.showError(context, message: '播放失败');
    } else if (total == 0) {
      ResponsiveSnackBar.show(context, message: '歌单为空');
    } else {
      ResponsiveSnackBar.show(context, message: '播放全部 $total 首歌曲');
    }
  }

  void _playSong(Song song, List<Song> songs, int index) {
    ref
        .read(playerStateProvider.notifier)
        .playPlaylist(
          songs,
          startIndex: index,
          sourcePlaylistId: _playlistIdInt,
        );
    ResponsiveSnackBar.show(context, message: '播放：${song.title}');
  }

  Future<void> _removeSong(int playlistId, Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除歌曲'),
        content: Text('确定从歌单中移除“${song.title}”吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(playlistNotifierProvider.notifier)
        .removeSongFromPlaylist(playlistId, song.id);
    if (success && mounted) {
      ResponsiveSnackBar.showSuccess(context, message: '歌曲已移除');
    }
  }

  Future<void> _deleteSongFromLibrary(Song song) async {
    final result = await DeleteSongDialog.show(
      context,
      title: '删除歌曲',
      content: '确定从歌曲库中删除“${song.title}”吗？',
    );
    if (result == null || !mounted) return;

    try {
      await ref
          .read(songsApiProvider)
          .deleteSong(song.id, deleteFiles: result.deleteFiles);
      ref.invalidate(playlistSongsProvider(_playlistIdInt));
      ref.invalidate(songsListProvider);
      _removeDeletedSongsFromPlayerQueue({song.id});
      if (mounted) {
        ResponsiveSnackBar.showSuccess(context, message: '歌曲已删除');
      }
    } catch (_) {
      if (mounted) {
        ResponsiveSnackBar.showError(context, message: '删除失败');
      }
    }
  }

  Future<void> _batchDeleteSelectedSongsFromLibrary() async {
    if (_selectedSongIds.isEmpty) return;
    final ids = _selectedSongIds.toSet();
    final result = await DeleteSongDialog.show(
      context,
      title: '批量删除',
      content: '确定从歌曲库中删除选中的 ${ids.length} 首歌曲吗？',
    );
    if (result == null || !mounted) return;

    try {
      final deleted = await ref
          .read(songsApiProvider)
          .batchDeleteSongs(ids.toList(), deleteFiles: result.deleteFiles);
      ref.invalidate(playlistSongsProvider(_playlistIdInt));
      ref.invalidate(songsListProvider);
      _removeDeletedSongsFromPlayerQueue(ids);
      _exitSelectMode();
      if (mounted) {
        ResponsiveSnackBar.showSuccess(context, message: '已删除 $deleted 首歌曲');
      }
    } catch (_) {
      if (mounted) {
        ResponsiveSnackBar.showError(context, message: '删除失败');
      }
    }
  }

  void _removeDeletedSongsFromPlayerQueue(Set<int> deletedIds) {
    final playerNotifier = ref.read(playerStateProvider.notifier);
    final queue = ref.read(playerStateProvider).playlist;
    for (var index = queue.length - 1; index >= 0; index--) {
      if (deletedIds.contains(queue[index].id)) {
        playerNotifier.removeFromPlaylist(index);
      }
    }
  }

  String _getLabelName(String label) {
    return switch (label) {
      'built_in' => '内置',
      'auto_created' => '自动创建',
      'hidden' => '隐藏',
      _ => label,
    };
  }

  Widget _buildError(String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 58,
              color: colorScheme.error,
            ),
            const SizedBox(height: 14),
            Text('加载失败', style: theme.textTheme.titleMedium),
            const SizedBox(height: 7),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重新加载'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistCover extends StatelessWidget {
  final Playlist playlist;
  final double size;
  final Color accent;

  const _PlaylistCover({
    required this.playlist,
    required this.size,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: playlist.coverImageUrl == null
          ? _PlaylistCoverPlaceholder(playlist: playlist)
          : ExcludeSemantics(
              child: CachedNetworkImage(
                imageUrl: UrlHelper.buildCoverUrl(playlist.coverImageUrl!),
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    Container(color: colorScheme.surfaceContainerHighest),
                errorWidget: (_, _, _) =>
                    _PlaylistCoverPlaceholder(playlist: playlist),
              ),
            ),
    );
  }
}

class _PlaylistCoverPlaceholder extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistCoverPlaceholder({required this.playlist});

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
        playlist.type == 'radio'
            ? Icons.radio_rounded
            : Icons.graphic_eq_rounded,
        size: 70,
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.72),
      ),
    );
  }
}

class _PlaylistMetaChip extends StatelessWidget {
  final String label;

  const _PlaylistMetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlaylistSongTile extends StatelessWidget {
  final Song song;
  final int index;
  final int displayIndex;
  final bool isCurrent;
  final bool selectionMode;
  final bool selected;
  final bool showDragHandle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelected;
  final VoidCallback? onRemove;
  final VoidCallback? onDelete;

  const _PlaylistSongTile({
    super.key,
    required this.song,
    required this.index,
    required this.displayIndex,
    required this.isCurrent,
    required this.onTap,
    this.selectionMode = false,
    this.selected = false,
    this.showDragHandle = false,
    this.onLongPress,
    this.onSelected,
    this.onRemove,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      child: Material(
        color: isCurrent
            ? colorScheme.primaryContainer.withValues(alpha: 0.52)
            : colorScheme.surfaceContainerLow.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(17),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 7, 8),
            child: Row(
              children: [
                if (showDragHandle)
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else if (selectionMode)
                  Checkbox(
                    value: selected,
                    onChanged: (_) => onSelected?.call(),
                  )
                else
                  SizedBox(
                    width: 34,
                    child: isCurrent
                        ? Icon(
                            Icons.equalizer_rounded,
                            color: colorScheme.primary,
                          )
                        : Text(
                            '$displayIndex',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                const SizedBox(width: 8),
                _SongCover(song: song),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isCurrent ? colorScheme.primary : null,
                          fontWeight: isCurrent
                              ? FontWeight.w800
                              : FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          song.artist ?? '未知艺术家',
                          if (song.album?.isNotEmpty == true) song.album!,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Formatters.formatDuration(song.duration),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (!selectionMode && !showDragHandle)
                  PopupMenuButton<String>(
                    tooltip: '歌曲操作',
                    icon: const Icon(Icons.more_horiz_rounded),
                    onSelected: (value) {
                      if (value == 'remove') onRemove?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'remove',
                        child: ListTile(
                          leading: Icon(Icons.playlist_remove_rounded),
                          title: Text('从歌单移除'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_outline_rounded,
                            color: colorScheme.error,
                          ),
                          title: Text(
                            '从歌曲库删除',
                            style: TextStyle(color: colorScheme.error),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SongCover extends StatelessWidget {
  final Song song;

  const _SongCover({required this.song});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final coverUrl = song.coverUrl;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: colorScheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: coverUrl == null
          ? Icon(Icons.music_note_rounded, color: colorScheme.onSurfaceVariant)
          : ExcludeSemantics(
              child: CachedNetworkImage(
                imageUrl: UrlHelper.buildCoverUrl(coverUrl),
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    Container(color: colorScheme.surfaceContainerHighest),
                errorWidget: (_, _, _) => Icon(
                  Icons.music_note_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
    );
  }
}

class _PlaylistEditDialog extends ConsumerStatefulWidget {
  final Playlist playlist;
  final int playlistId;

  const _PlaylistEditDialog({required this.playlist, required this.playlistId});

  @override
  ConsumerState<_PlaylistEditDialog> createState() =>
      _PlaylistEditDialogState();
}

class _PlaylistEditDialogState extends ConsumerState<_PlaylistEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  String? _coverMode;
  PlatformFile? _localFile;
  String? _selectedCoverUrl;
  int? _selectedCoverSongId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist.name);
    _descriptionController = TextEditingController(
      text: widget.playlist.description,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? get _previewCoverUrl {
    if (_coverMode == 'clear') return null;
    if (_coverMode == 'song') return _selectedCoverUrl;
    if (_coverMode == 'local') return _localFile?.path;
    return widget.playlist.coverUrl;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasCover =
        _coverMode != 'clear' &&
        (_coverMode == 'local' ||
            _coverMode == 'song' ||
            widget.playlist.coverUrl?.isNotEmpty == true);

    return AlertDialog(
      title: Text(widget.playlist.isBuiltIn ? '修改歌单封面' : '编辑歌单'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 142,
                height: 142,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildCoverPreview(colorScheme),
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickLocalImage,
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: const Text('上传图片'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickFromSongs,
                    icon: const Icon(Icons.music_note_rounded, size: 18),
                    label: const Text('从歌曲选择'),
                  ),
                  if (hasCover)
                    TextButton.icon(
                      onPressed: _saving ? null : _clearCover,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: colorScheme.error,
                      ),
                      label: Text(
                        '清除',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                enabled: !_saving && !widget.playlist.isBuiltIn,
                decoration: const InputDecoration(
                  labelText: '歌单名称',
                  prefixIcon: Icon(Icons.queue_music_rounded),
                ),
              ),
              const SizedBox(height: 13),
              TextField(
                controller: _descriptionController,
                enabled: !_saving && !widget.playlist.isBuiltIn,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '歌单描述',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _pickLocalImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: kIsWeb,
      );
      if (result != null && result.files.isNotEmpty && mounted) {
        setState(() {
          _localFile = result.files.first;
          _coverMode = 'local';
        });
      }
    } catch (error) {
      if (mounted) {
        ResponsiveSnackBar.showError(context, message: '选择图片失败：$error');
      }
    }
  }

  Future<void> _pickFromSongs() async {
    final result = await showSongCoverPicker(context, widget.playlistId);
    if (result != null && mounted) {
      setState(() {
        _selectedCoverSongId = result['songId'] as int?;
        _selectedCoverUrl = result['coverUrl'] as String?;
        _coverMode = 'song';
        _localFile = null;
      });
    }
  }

  void _clearCover() {
    setState(() {
      _coverMode = 'clear';
      _localFile = null;
      _selectedCoverUrl = null;
      _selectedCoverSongId = null;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ResponsiveSnackBar.showError(context, message: '请输入歌单名称');
      return;
    }

    setState(() => _saving = true);
    try {
      final notifier = ref.read(playlistNotifierProvider.notifier);
      final description = _descriptionController.text.trim();

      if (_coverMode == 'local' && _localFile != null) {
        final file = _localFile!;
        final uploaded = await notifier.uploadPlaylistCover(
          widget.playlistId,
          bytes: file.bytes,
          filePath: file.path,
          fileName: file.name,
        );
        if (uploaded == null) {
          if (mounted) {
            ResponsiveSnackBar.showError(context, message: '封面上传失败');
          }
          return;
        }
        await notifier.updatePlaylist(
          widget.playlistId,
          name: name,
          description: description.isEmpty ? null : description,
        );
      } else if (_coverMode == 'song' && _selectedCoverSongId != null) {
        await notifier.updatePlaylist(
          widget.playlistId,
          name: name,
          description: description.isEmpty ? null : description,
          coverSongId: _selectedCoverSongId,
        );
      } else if (_coverMode == 'clear') {
        await notifier.updatePlaylist(
          widget.playlistId,
          name: name,
          description: description.isEmpty ? null : description,
          coverPath: '',
        );
      } else {
        await notifier.updatePlaylist(
          widget.playlistId,
          name: name,
          description: description.isEmpty ? null : description,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ResponsiveSnackBar.showError(context, message: '保存失败：$error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildCoverPreview(ColorScheme colorScheme) {
    if (_coverMode == 'local' && _localFile != null) {
      if (kIsWeb && _localFile!.bytes != null) {
        return Image.memory(_localFile!.bytes!, fit: BoxFit.cover);
      }
      if (!kIsWeb && _localFile!.path != null) {
        return Image.file(File(_localFile!.path!), fit: BoxFit.cover);
      }
    }

    final previewUrl = _previewCoverUrl;
    if (previewUrl?.isNotEmpty == true) {
      return ExcludeSemantics(
        child: CachedNetworkImage(
          imageUrl: UrlHelper.buildCoverUrl(previewUrl!),
          fit: BoxFit.cover,
          placeholder: (_, _) =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorWidget: (_, _, _) => _buildPlaceholder(colorScheme),
        ),
      );
    }
    return _buildPlaceholder(colorScheme);
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primaryContainer, colorScheme.tertiaryContainer],
        ),
      ),
      child: Icon(
        Icons.queue_music_rounded,
        size: 54,
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.72),
      ),
    );
  }
}
