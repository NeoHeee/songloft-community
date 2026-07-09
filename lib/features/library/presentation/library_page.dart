import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/responsive.dart';
import '../../../shared/models/song.dart';
import '../../../shared/utils/responsive_snackbar.dart';
import '../../../shared/widgets/add_to_playlist_modal.dart';
import '../../../shared/widgets/delete_song_dialog.dart';
import '../../player/presentation/providers/player_provider.dart';
import 'providers/songs_provider.dart';
import 'song_edit_page.dart';
import 'widgets/song_filter_bar.dart';
import 'widgets/song_list_tile.dart';

/// 歌曲库页面
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(songsListProvider.notifier).loadSongs();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(songsListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(songsListProvider.notifier).search(value);
    });
  }

  Future<void> _playAll(SongsListState state) async {
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(songsListProvider);

    return Scaffold(
      appBar: _buildAppBar(context, state),
      body: Column(
        children: [
          if (!state.isSelectionMode) _buildLibraryHeader(context, state),
          SongFilterBar(
            currentType: state.type,
            onTypeChanged: (type) {
              ref.read(songsListProvider.notifier).setTypeFilter(type);
            },
            songCount: state.total,
          ),
          if (state.error != null) _buildErrorBanner(state.error!),
          Expanded(child: _buildSongList(context, state)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, SongsListState state) {
    if (!state.isSelectionMode) {
      return AppBar(
        title: const Text('歌曲库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            tooltip: '多选',
            onPressed: () {
              ref.read(songsListProvider.notifier).toggleSelectMode();
            },
          ),
        ],
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        tooltip: '退出多选',
        onPressed: () {
          ref.read(songsListProvider.notifier).toggleSelectMode();
        },
      ),
      title: Text('已选择 ${state.selectedSongIds.length} 首'),
      actions: [
        IconButton(
          icon: const Icon(Icons.playlist_add_rounded),
          tooltip: '添加到歌单',
          onPressed: state.selectedSongIds.isEmpty
              ? null
              : () => _showAddToPlaylistDialog(
                    context,
                    state.selectedSongIds.toList(),
                  ),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
          tooltip: '批量删除',
          onPressed: state.selectedSongIds.isEmpty
              ? null
              : () => _showBatchDeleteConfirmDialog(context),
        ),
        TextButton(
          onPressed: state.isSelectingAll
              ? null
              : () {
                  ref.read(songsListProvider.notifier).toggleSelectAll();
                },
          child: state.isSelectingAll
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  state.total > 0 &&
                          state.selectedSongIds.length >= state.total
                      ? '取消全选'
                      : '全选',
                ),
        ),
      ],
    );
  }

  Widget _buildLibraryHeader(BuildContext context, SongsListState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final horizontalPadding = context.responsive<double>(
      mobile: 12,
      tablet: 18,
      desktop: 24,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.24),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final searchField = _buildSearchField(context);
                final actions = _buildHeaderActions(context, state);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primaryContainer,
                                colorScheme.tertiaryContainer,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.library_music_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '整理你的音乐世界',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.keyword.isEmpty
                                    ? '共 ${state.total} 首歌曲，可搜索、筛选或直接播放'
                                    : '正在搜索“${state.keyword}”，找到 ${state.total} 首',
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
                    const SizedBox(height: 14),
                    if (compact) ...[
                      searchField,
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: actions,
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(child: searchField),
                          const SizedBox(width: 12),
                          actions,
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '搜索歌曲、艺术家或专辑',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: '清除搜索',
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                  ref.read(songsListProvider.notifier).search('');
                },
              ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.18),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      ),
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildHeaderActions(BuildContext context, SongsListState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: state.songs.isEmpty ? null : () => _playAll(state),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('播放全部'),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: '排序',
          icon: const Icon(Icons.swap_vert_rounded),
          onSelected: (value) {
            final (sort, order) = switch (value) {
              'added_at' => ('added_at', 'desc'),
              'file_modified_at' => ('file_modified_at', 'desc'),
              'title' => ('title', 'asc'),
              'artist' => ('artist', 'asc'),
              'duration' => ('duration', 'asc'),
              _ => ('added_at', 'desc'),
            };
            ref.read(songsListProvider.notifier).setSort(sort, order);
          },
          itemBuilder: (context) => [
            _buildLibrarySortItem(
              value: 'added_at',
              icon: Icons.schedule_rounded,
              title: '最近加入',
              isSelected: state.sort == 'added_at',
            ),
            _buildLibrarySortItem(
              value: 'file_modified_at',
              icon: Icons.insert_drive_file_outlined,
              title: '文件时间',
              isSelected: state.sort == 'file_modified_at',
            ),
            _buildLibrarySortItem(
              value: 'title',
              icon: Icons.sort_by_alpha_rounded,
              title: '标题',
              isSelected: state.sort == 'title',
            ),
            _buildLibrarySortItem(
              value: 'artist',
              icon: Icons.person_rounded,
              title: '艺术家',
              isSelected: state.sort == 'artist',
            ),
            _buildLibrarySortItem(
              value: 'duration',
              icon: Icons.timer_outlined,
              title: '时长',
              isSelected: state.sort == 'duration',
            ),
          ],
        ),
        PopupMenuButton<String>(
          tooltip: '更多操作',
          icon: const Icon(Icons.add_rounded),
          onSelected: (value) {
            switch (value) {
              case 'add_remote':
                _navigateToAddSong(context, AppConstants.songTypeRemote);
              case 'add_radio':
                _navigateToAddSong(context, AppConstants.songTypeRadio);
              case 'toggle_hidden':
                ref
                    .read(songsListProvider.notifier)
                    .setShowHidden(!state.showHidden);
              case 'clean':
                _showCleanConfirmDialog(context);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'add_remote',
              child: ListTile(
                leading: Icon(Icons.cloud_rounded),
                title: Text('添加网络歌曲'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'add_radio',
              child: ListTile(
                leading: Icon(Icons.radio_rounded),
                title: Text('添加电台'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'toggle_hidden',
              child: ListTile(
                leading: Icon(
                  state.showHidden
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
                title: Text(
                  state.showHidden ? '隐藏已隐藏歌曲' : '显示隐藏歌曲',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'clean',
              child: ListTile(
                leading: Icon(Icons.cleaning_services_rounded),
                title: Text('清理无效歌曲'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildLibrarySortItem({
    required String value,
    required IconData icon,
    required String title,
    required bool isSelected,
  }) {
    final color = isSelected ? Theme.of(context).colorScheme.primary : null;
    return PopupMenuItem<String>(
      value: value,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: isSelected ? Icon(Icons.check_rounded, color: color) : null,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Material(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: colorScheme.error),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: '关闭提示',
                color: colorScheme.onErrorContainer,
                onPressed: () {
                  ref.read(songsListProvider.notifier).clearError();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSongList(BuildContext context, SongsListState state) {
    if (state.isLoading && state.songs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.songs.isEmpty) {
      return _buildEmptyState(context);
    }

    final contentPadding = context.responsive<double>(
      mobile: 0,
      tablet: AppSpacing.sm,
      desktop: AppSpacing.md,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(songsListProvider.notifier).refresh(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: contentPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (context.isMobile ||
                constraints.maxWidth < ResponsiveBreakpoints.tablet) {
              return _buildMobileList(context, state);
            }
            return _buildDesktopList(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, SongsListState state) {
    final currentSong = ref.watch(currentSongProvider);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 2, bottom: 90),
      itemCount: state.songs.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.songs.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final song = state.songs[index];
        return SongListTile(
          song: song,
          index: index,
          isSelected: state.selectedSongIds.contains(song.id),
          isSelectionMode: state.isSelectionMode,
          isCurrentSong: currentSong?.id == song.id,
          onTap: () => _onSongTap(song, index),
          onLongPress: () {
            ref.read(songsListProvider.notifier).toggleSelectMode();
            ref.read(songsListProvider.notifier).toggleSongSelection(song.id);
          },
          onSelect: () {
            ref.read(songsListProvider.notifier).toggleSongSelection(song.id);
          },
          onDelete: () => _showDeleteConfirmDialog(context, song.id),
          onEdit: song.type != AppConstants.songTypeLocal
              ? () => _navigateToEditSong(context, song)
              : null,
          onAddToPlaylist: () => _showAddToPlaylistDialog(context, [song.id]),
        );
      },
    );
  }

  Widget _buildDesktopList(BuildContext context, SongsListState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentSong = ref.watch(currentSongProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 700;

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (state.isSelectionMode)
                        const SizedBox(width: 48)
                      else
                        SizedBox(
                          width: 40,
                          child: Text(
                            '#',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(width: 64),
                      _headerLabel(theme, colorScheme, '标题', flex: 3),
                      const SizedBox(width: 16),
                      _headerLabel(theme, colorScheme, '艺术家', flex: 2),
                      if (!isNarrow) ...[
                        const SizedBox(width: 16),
                        _headerLabel(theme, colorScheme, '专辑', flex: 2),
                      ],
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '类型',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '时长',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 148),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount:
                        state.songs.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.songs.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final song = state.songs[index];
                      return SongListTile(
                        song: song,
                        index: index,
                        isSelected: state.selectedSongIds.contains(song.id),
                        isSelectionMode: state.isSelectionMode,
                        isNarrow: isNarrow,
                        isCurrentSong: currentSong?.id == song.id,
                        onTap: () => _onSongTap(song, index),
                        onLongPress: () {
                          ref
                              .read(songsListProvider.notifier)
                              .toggleSelectMode();
                          ref
                              .read(songsListProvider.notifier)
                              .toggleSongSelection(song.id);
                        },
                        onSelect: () {
                          ref
                              .read(songsListProvider.notifier)
                              .toggleSongSelection(song.id);
                        },
                        onDelete: () =>
                            _showDeleteConfirmDialog(context, song.id),
                        onEdit: song.type != AppConstants.songTypeLocal
                            ? () => _navigateToEditSong(context, song)
                            : null,
                        onAddToPlaylist: () =>
                            _showAddToPlaylistDialog(context, [song.id]),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _headerLabel(
    ThemeData theme,
    ColorScheme colorScheme,
    String label, {
    required int flex,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final state = ref.watch(songsListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSearch = state.keyword.isNotEmpty;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.tertiaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                isSearch ? Icons.search_off_rounded : Icons.library_music_rounded,
                size: 42,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearch ? '没有找到匹配的歌曲' : '歌曲库还是空的',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              isSearch ? '换一个关键词，或者调整上方筛选条件' : '添加网络歌曲、电台，或扫描本地音乐开始使用',
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

  Future<void> _navigateToAddSong(
    BuildContext context,
    String songType,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SongEditPage(songType: songType),
      ),
    );
    if (result == true) {
      ref.read(songsListProvider.notifier).refresh();
    }
  }

  Future<void> _navigateToEditSong(
    BuildContext context,
    Song song,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SongEditPage(song: song, songType: song.type),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理歌曲'),
        content: const Text('将清理无效的歌曲记录（如文件已删除的本地歌曲）。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final cleaned =
                  await ref.read(songsListProvider.notifier).cleanSongs();
              if (context.mounted) {
                ResponsiveSnackBar.show(
                  context,
                  message: '已清理 $cleaned 首无效歌曲',
                );
              }
            },
            child: const Text('清理'),
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, List<int> songIds) {
    AddToPlaylistModal.show(context, songIds: songIds);
  }

  Future<void> _showBatchDeleteConfirmDialog(BuildContext context) async {
    final count = ref.read(songsListProvider).selectedSongIds.length;
    final result = await DeleteSongDialog.show(
      context,
      title: '批量删除',
      content: '确定要删除选中的 $count 首歌曲吗？',
    );
    if (result != null) {
      final deleted = await ref
          .read(songsListProvider.notifier)
          .batchDeleteSongs(deleteFiles: result.deleteFiles);
      if (context.mounted) {
        if (deleted > 0) {
          ResponsiveSnackBar.showSuccess(
            context,
            message: '已删除 $deleted 首歌曲',
          );
        } else {
          ResponsiveSnackBar.showError(context, message: '删除失败');
        }
      }
    }
  }
}
