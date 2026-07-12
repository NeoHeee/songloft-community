import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants.dart';
import '../../../core/storage/mobile_tab_memory.dart';
import '../../../shared/models/song.dart';
import '../../../shared/utils/responsive_snackbar.dart';
import '../../../shared/widgets/add_to_playlist_modal.dart';
import '../../../shared/widgets/delete_song_dialog.dart';
import '../../player/presentation/providers/player_provider.dart';
import 'providers/songs_provider.dart';
import 'song_edit_page.dart';
import 'widgets/library_actions_sheet.dart';
import 'widgets/song_filter_bar.dart';
import 'widgets/song_list_tile.dart';

/// 第四轮手机端歌曲库：单一滚动容器、浮动 AppBar、吸顶搜索与筛选。
class MobileLibraryPage extends ConsumerStatefulWidget {
  const MobileLibraryPage({super.key});

  @override
  ConsumerState<MobileLibraryPage> createState() => _MobileLibraryPageState();
}

class _MobileLibraryPageState extends ConsumerState<MobileLibraryPage> {
  late final ScrollController _scrollController;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final rememberedSearch = ref.read(songsListProvider).keyword;
    _searchController.text = rememberedSearch;
    MobileTabMemory.librarySearch = rememberedSearch;
    _scrollController = ScrollController(
      initialScrollOffset: MobileTabMemory.libraryScrollOffset,
    )..addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(songsListProvider);
      if (state.songs.isEmpty && !state.isLoading) {
        ref.read(songsListProvider.notifier).loadSongs();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    MobileTabMemory.libraryScrollOffset = position.pixels;
    if (position.pixels >= position.maxScrollExtent - 260) {
      ref.read(songsListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    MobileTabMemory.librarySearch = value;
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(songsListProvider.notifier).search(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    MobileTabMemory.librarySearch = '';
    setState(() {});
    ref.read(songsListProvider.notifier).search('');
  }

  Future<void> _refreshLibrary() async {
    await ref.read(songsListProvider.notifier).refresh();
    if (!mounted) return;
    if (ref.read(songsListProvider).error == null) {
      ResponsiveSnackBar.showSuccess(context, message: '歌曲库已刷新');
    }
  }

  Future<void> _playAll(SongsListState state) async {
    HapticFeedback.lightImpact();
    final total = await ref
        .read(playerStateProvider.notifier)
        .playAllSongs(keyword: state.keyword, type: state.type);
    if (!mounted) return;

    if (total < 0) {
      ResponsiveSnackBar.showError(context, message: '播放失败');
    } else if (total == 0) {
      ResponsiveSnackBar.show(context, message: '没有可播放的歌曲');
    } else {
      ResponsiveSnackBar.show(context, message: '播放全部 $total 首歌曲');
    }
  }

  Future<bool> _handleBackButton() async {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
      return true;
    }

    final state = ref.read(songsListProvider);
    if (state.isSelectionMode) {
      ref.read(songsListProvider.notifier).exitSelectionMode();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(songsListProvider);
    final currentSong = ref.watch(currentSongProvider);

    return BackButtonListener(
      onBackButtonPressed: _handleBackButton,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _refreshLibrary,
          child: CustomScrollView(
            key: const PageStorageKey<String>('mobile-library-scroll'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(state),
              if (!state.isSelectionMode)
                SliverToBoxAdapter(child: _buildIntroCard(state)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _LibraryControlsDelegate(
                  extent: state.isSelectionMode ? 160 : 142,
                  child: state.isSelectionMode
                      ? SongFilterBar(
                          currentType: state.type,
                          onTypeChanged: (_) {},
                          songCount: state.total,
                        )
                      : _buildPinnedControls(state),
                ),
              ),
              if (state.error != null)
                SliverToBoxAdapter(child: _buildErrorBanner(state.error!)),
              ..._buildSongSlivers(state, currentSong),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(SongsListState state) {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      title: Text(
        state.isSelectionMode ? '已选择 ${state.selectedSongIds.length} 首' : '歌曲库',
      ),
      leading: state.isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: '退出多选',
              onPressed: () =>
                  ref.read(songsListProvider.notifier).exitSelectionMode(),
            )
          : null,
      actions: [
        if (!state.isSelectionMode)
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            tooltip: '多选歌曲',
            onPressed: () =>
                ref.read(songsListProvider.notifier).enterSelectionMode(),
          ),
      ],
    );
  }

  Widget _buildIntroCard(SongsListState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.tertiaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.library_music_rounded,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '整理你的音乐世界',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.keyword.isEmpty
                        ? '共 ${state.total} 首歌曲，向下滑动开始浏览'
                        : '搜索“${state.keyword}”，找到 ${state.total} 首',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
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

  Widget _buildPinnedControls(SongsListState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          children: [
            SizedBox(height: 50, child: _buildSearchField()),
            const SizedBox(height: 7),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: state.songs.isEmpty ? null : () => _playAll(state),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('播放全部'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildTypeFilters(state)),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  onPressed: () => _showActionsSheet(state),
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: '更多操作',
                  style: IconButton.styleFrom(minimumSize: const Size(46, 46)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: '搜索歌曲、艺术家或专辑',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: '清除搜索',
                onPressed: _clearSearch,
              ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildTypeFilters(SongsListState state) {
    const filters = <(String?, String)>[
      (null, '全部'),
      (AppConstants.songTypeLocal, '本地'),
      (AppConstants.songTypeRemote, '网络'),
      (AppConstants.songTypeRadio, '电台'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: ChoiceChip(
                selected: state.type == filter.$1,
                label: Text(filter.$2),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  ref.read(songsListProvider.notifier).setTypeFilter(filter.$1);
                },
                materialTapTargetSize: MaterialTapTargetSize.padded,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  void _showActionsSheet(SongsListState state) {
    HapticFeedback.selectionClick();
    LibraryActionsSheet.show(
      context,
      currentSort: state.sort,
      showHidden: state.showHidden,
      onSortChanged: _setSort,
      onAddRemote: () =>
          _navigateToAddSong(context, AppConstants.songTypeRemote),
      onAddRadio: () => _navigateToAddSong(context, AppConstants.songTypeRadio),
      onToggleHidden: () =>
          ref.read(songsListProvider.notifier).setShowHidden(!state.showHidden),
      onClean: () => _showCleanConfirmDialog(context),
    );
  }

  void _setSort(String value) {
    final (sort, order) = switch (value) {
      'added_at' => ('added_at', 'desc'),
      'file_modified_at' => ('file_modified_at', 'desc'),
      'title' => ('title', 'asc'),
      'artist' => ('artist', 'asc'),
      'duration' => ('duration', 'asc'),
      _ => ('added_at', 'desc'),
    };
    ref.read(songsListProvider.notifier).setSort(sort, order);
  }

  Widget _buildErrorBanner(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Material(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: colorScheme.error),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
              TextButton(
                onPressed: () => ref.read(songsListProvider.notifier).refresh(),
                child: const Text('重试'),
              ),
              IconButton(
                onPressed: () =>
                    ref.read(songsListProvider.notifier).clearError(),
                icon: const Icon(Icons.close_rounded),
                tooltip: '关闭提示',
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSongSlivers(SongsListState state, Song? currentSong) {
    if (state.isLoading && state.songs.isEmpty) {
      return [
        SliverList.builder(
          itemCount: 8,
          itemBuilder: (_, index) => const _SongSkeleton(),
        ),
      ];
    }

    if (state.songs.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(state),
        ),
      ];
    }

    return [
      SliverList.builder(
        itemCount: state.songs.length,
        itemBuilder: (context, index) {
          final song = state.songs[index];
          return SongListTile(
            song: song,
            index: index,
            isSelected: state.selectedSongIds.contains(song.id),
            isSelectionMode: state.isSelectionMode,
            isCurrentSong: currentSong?.id == song.id,
            onTap: () => _onSongTap(song, index),
            onLongPress: () => ref
                .read(songsListProvider.notifier)
                .enterSelectionMode(initialSongId: song.id),
            onSelect: () => ref
                .read(songsListProvider.notifier)
                .toggleSongSelection(song.id),
            onDelete: () => _showDeleteConfirmDialog(context, song.id),
            onEdit: song.type == AppConstants.songTypeLocal
                ? null
                : () => _navigateToEditSong(context, song),
            onAddToPlaylist: () =>
                AddToPlaylistModal.show(context, songIds: [song.id]),
          );
        },
      ),
      if (state.isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ];
  }

  Widget _buildEmptyState(SongsListState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final searching = state.keyword.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching
                  ? Icons.search_off_rounded
                  : Icons.library_music_rounded,
              size: 54,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              searching ? '没有找到匹配的歌曲' : '歌曲库还是空的',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              searching ? '换一个关键词或筛选条件试试' : '通过右上方操作面板添加网络歌曲或电台',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSongTap(Song song, int index) {
    final state = ref.read(songsListProvider);
    final notifier = ref.read(playerStateProvider.notifier);
    notifier.playPlaylist(state.songs, startIndex: index);
    if (state.hasMore) {
      notifier.loadRemainingSongsForCurrentPlaylist(
        keyword: state.keyword,
        type: state.type,
        loadedCount: state.songs.length,
        total: state.total,
      );
    }
  }

  Future<void> _navigateToAddSong(BuildContext context, String songType) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SongEditPage(songType: songType)),
    );
    if (result == true) {
      ref.read(songsListProvider.notifier).refresh();
    }
  }

  Future<void> _navigateToEditSong(BuildContext context, Song song) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SongEditPage(song: song, songType: song.type),
      ),
    );
    if (result == true) {
      ref.read(songsListProvider.notifier).refresh();
    }
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    int songId,
  ) async {
    final result = await DeleteSongDialog.show(
      context,
      title: '确认删除',
      content: '确定要删除这首歌曲吗？',
    );
    if (result != null) {
      await ref
          .read(songsListProvider.notifier)
          .deleteSong(songId, deleteFiles: result.deleteFiles);
    }
  }

  void _showCleanConfirmDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清理歌曲'),
        content: const Text('将清理无效的歌曲记录，例如文件已删除的本地歌曲。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final cleaned = await ref
                  .read(songsListProvider.notifier)
                  .cleanSongs();
              if (!context.mounted) return;
              ResponsiveSnackBar.show(context, message: '已清理 $cleaned 首无效歌曲');
            },
            child: const Text('清理'),
          ),
        ],
      ),
    );
  }
}

class _LibraryControlsDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final Widget child;

  const _LibraryControlsDelegate({required this.extent, required this.child});

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _LibraryControlsDelegate oldDelegate) {
    return oldDelegate.extent != extent || oldDelegate.child != child;
  }
}

class _SongSkeleton extends StatelessWidget {
  const _SongSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
