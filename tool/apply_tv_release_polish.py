from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding='utf-8')


def write(path: str, content: str) -> None:
    target = ROOT / path
    target.write_text(content, encoding='utf-8')


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f'missing patch anchor: {label}')
    return text.replace(old, new, 1)


def patch_tv_focusable() -> None:
    path = 'lib/shared/widgets/tv_focusable.dart'
    text = read(path)
    if 'final VoidCallback? onLongSelect;' in text:
        return

    text = replace_once(
        text,
        "import 'package:flutter/material.dart';\n",
        "import 'dart:async';\n\nimport 'package:flutter/material.dart';\n",
        'TvFocusable timer import',
    )
    text = replace_once(
        text,
        '  /// Enter/Select 按下时触发\n  final VoidCallback? onSelect;\n',
        '''  /// Enter/Select 短按时触发
  final VoidCallback? onSelect;

  /// Enter/Select 长按时触发
  final VoidCallback? onLongSelect;

  /// 长按识别时长
  final Duration longPressDuration;
''',
        'TvFocusable long select fields',
    )
    text = replace_once(
        text,
        '    this.onSelect,\n    this.autofocus = false,\n',
        '''    this.onSelect,
    this.onLongSelect,
    this.longPressDuration = const Duration(milliseconds: 650),
    this.autofocus = false,
''',
        'TvFocusable long select constructor',
    )
    text = replace_once(
        text,
        '  late FocusNode _focusNode;\n  bool _hasFocus = false;\n',
        '''  late FocusNode _focusNode;
  bool _hasFocus = false;
  Timer? _longPressTimer;
  bool _longPressTriggered = false;
''',
        'TvFocusable long press state',
    )
    text = replace_once(
        text,
        '  @override\n  void dispose() {\n',
        '''  @override
  void dispose() {
    _longPressTimer?.cancel();
''',
        'TvFocusable timer dispose',
    )

    old_handler = '''    if (!widget.enabled || widget.onSelect == null) {
      return KeyEventResult.ignored;
    }

    // 只处理按下事件
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    // 处理 Enter 键和 Select 键（遥控器确认键）
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA ||
        event.logicalKey == LogicalKeyboardKey.space) {
      widget.onSelect?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
'''
    new_handler = '''    if (!widget.enabled ||
        (widget.onSelect == null && widget.onLongSelect == null)) {
      return KeyEventResult.ignored;
    }

    final isConfirm = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA ||
        event.logicalKey == LogicalKeyboardKey.space;
    if (!isConfirm) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      _longPressTimer?.cancel();
      _longPressTriggered = false;
      if (widget.onLongSelect != null) {
        _longPressTimer = Timer(widget.longPressDuration, () {
          if (!mounted) return;
          _longPressTriggered = true;
          widget.onLongSelect?.call();
        });
      }
      return KeyEventResult.handled;
    }

    if (event is KeyRepeatEvent) {
      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent) {
      _longPressTimer?.cancel();
      if (!_longPressTriggered) widget.onSelect?.call();
      _longPressTriggered = false;
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
'''
    text = replace_once(text, old_handler, new_handler, 'TvFocusable long press handler')
    text = replace_once(
        text,
        '          onTap: widget.enabled ? widget.onSelect : null,\n',
        '''          onTap: widget.enabled ? widget.onSelect : null,
          onLongPress: widget.enabled ? widget.onLongSelect : null,
''',
        'TvFocusable gesture long press',
    )
    write(path, text)


def patch_adaptive_scaffold() -> None:
    path = 'lib/shared/layouts/adaptive_scaffold.dart'
    text = read(path)
    if "../widgets/tv_action_dialog.dart" not in text:
        text = replace_once(
            text,
            "import '../../core/theme/tv_theme.dart';\n",
            "import '../../core/theme/tv_theme.dart';\nimport '../widgets/tv_action_dialog.dart';\n",
            'AdaptiveScaffold action dialog import',
        )

    old_nav = '''                  Expanded(
                    child: FocusTraversalGroup(
                      policy: OrderedTraversalPolicy(),
                      child: Row(
                        children:
                            destinations.asMap().entries.map((entry) {
                              final index = entry.key;
                              final dest = entry.value;
                              final isSelected = index == currentIndex;
                              return Padding(
                                padding: const EdgeInsets.only(
                                  right: TvTheme.spacingMedium,
                                ),
                                child: _TvNavButton(
                                  icon:
                                      isSelected
                                          ? dest.selectedIcon
                                          : dest.icon,
                                  label: dest.label,
                                  isSelected: isSelected,
                                  onPressed: () => onDestinationSelected(index),
                                  autofocus: index == currentIndex,
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),'''
    new_nav = '''                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final visibleIndices = _tvVisibleIndices(
                          constraints.maxWidth,
                        );
                        final overflowIndices = <int>[
                          for (var index = 0;
                              index < destinations.length;
                              index++)
                            if (!visibleIndices.contains(index)) index,
                        ];
                        final selectedInOverflow =
                            overflowIndices.contains(currentIndex);

                        return FocusTraversalGroup(
                          policy: OrderedTraversalPolicy(),
                          child: Row(
                            children: [
                              for (final index in visibleIndices)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: TvTheme.spacingSmall,
                                  ),
                                  child: _TvNavButton(
                                    icon: index == currentIndex
                                        ? destinations[index].selectedIcon
                                        : destinations[index].icon,
                                    label: destinations[index].label,
                                    isSelected: index == currentIndex,
                                    onPressed: () =>
                                        onDestinationSelected(index),
                                    autofocus: index == currentIndex,
                                  ),
                                ),
                              if (overflowIndices.isNotEmpty)
                                _TvNavButton(
                                  icon: Icon(
                                    selectedInOverflow
                                        ? Icons.apps_rounded
                                        : Icons.apps_outlined,
                                  ),
                                  label: selectedInOverflow
                                      ? destinations[currentIndex].label
                                      : '更多',
                                  isSelected: selectedInOverflow,
                                  onPressed: () => _showTvOverflowMenu(
                                    context,
                                    overflowIndices,
                                  ),
                                  autofocus: selectedInOverflow,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),'''
    text = replace_once(text, old_nav, new_nav, 'TV navigation overflow')

    insert_anchor = '  }\n}\n\n/// TV 导航按钮组件'
    helpers = '''  List<int> _tvVisibleIndices(double availableWidth) {
    if (destinations.length <= 5) {
      return List<int>.generate(destinations.length, (index) => index);
    }

    final maxButtons = (availableWidth / 154).floor().clamp(3, 7);
    final realSlots = (maxButtons - 1).clamp(2, destinations.length);
    final lastIndex = destinations.length - 1;
    final visible = <int>{0, lastIndex};

    if (currentIndex > 0 && currentIndex < lastIndex) {
      visible.add(currentIndex);
    }
    for (var index = 1;
        index < lastIndex && visible.length < realSlots;
        index++) {
      visible.add(index);
    }

    final result = visible.toList()..sort();
    return result;
  }

  void _showTvOverflowMenu(BuildContext context, List<int> indices) {
    showTvActionDialog(
      context: context,
      title: '更多功能',
      actions: [
        for (final index in indices)
          TvActionItem(
            icon: index == currentIndex
                ? Icons.radio_button_checked_rounded
                : Icons.apps_rounded,
            label: destinations[index].label,
            onPressed: () => onDestinationSelected(index),
          ),
      ],
    );
  }
'''
    text = replace_once(text, insert_anchor, '  }\n\n' + helpers + '}\n\n/// TV 导航按钮组件', 'TV overflow helpers')
    write(path, text)


def patch_song_list_tile() -> None:
    path = 'lib/features/library/presentation/widgets/song_list_tile.dart'
    text = read(path)
    text = text.replace(
        '      onKeyEvent: (node, event) => _handleTvKey(context, ref, event),\n      onSelect: action,',
        '''      onKeyEvent: (node, event) => _handleTvKey(context, ref, event),
      onLongSelect: isSelectionMode ? null : () => _showTvActions(context, ref),
      onSelect: action,''',
        1,
    )
    text = text.replace(
        '''    if (key == LogicalKeyboardKey.contextMenu ||
        key == LogicalKeyboardKey.gameButtonY ||
        key == LogicalKeyboardKey.keyM ||
        key == LogicalKeyboardKey.delete) {''',
        '''    if (key == LogicalKeyboardKey.contextMenu ||
        key == LogicalKeyboardKey.gameButtonY ||
        key == LogicalKeyboardKey.keyM ||
        key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.arrowRight) {''',
        1,
    )
    write(path, text)


def patch_playlist_widgets() -> None:
    for path in [
        'lib/features/playlist/presentation/widgets/playlist_card.dart',
        'lib/features/playlist/presentation/widgets/playlist_list_item.dart',
    ]:
        text = read(path)
        if "package:flutter/services.dart" not in text:
            text = replace_once(
                text,
                "import 'package:flutter/material.dart';\n",
                "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';\n",
                f'{path} services import',
            )
        old = '''      autofocus: autofocus,
      onSelect: action,
      enabled: action != null,'''
        new = '''      autofocus: autofocus,
      onSelect: action,
      onLongSelect: isSelectionMode ? null : onLongPress,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowRight &&
            !isSelectionMode &&
            onLongPress != null) {
          onLongPress!.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      enabled: action != null,'''
        text = replace_once(text, old, new, f'{path} TV menu access')
        write(path, text)


def patch_playlist_drawer() -> None:
    path = 'lib/features/player/presentation/widgets/playlist_drawer.dart'
    text = read(path)
    text = replace_once(
        text,
        '''        onSelect: onTap,
        onKeyEvent: (_, event) {''',
        '''        onSelect: onTap,
        onLongSelect: onShowActions,
        onKeyEvent: (_, event) {''',
        'queue long select',
    )
    text = text.replace(
        '''              key == LogicalKeyboardKey.keyM ||
              key == LogicalKeyboardKey.delete) {''',
        '''              key == LogicalKeyboardKey.keyM ||
              key == LogicalKeyboardKey.delete ||
              key == LogicalKeyboardKey.arrowRight) {''',
        1,
    )
    write(path, text)


def patch_tv_player() -> None:
    path = 'lib/features/player/presentation/widgets/tv_player.dart'
    text = read(path)
    text = text.replace('        editable: true,', '        editable: false,', 1)
    text = text.replace('              autofocus: true,\n', '', 1)
    write(path, text)


def patch_library_page() -> None:
    path = 'lib/features/library/presentation/library_page.dart'
    text = read(path)
    if 'Future<void> _refreshTvLibrary()' not in text:
        insert = '''  Future<void> _refreshTvLibrary() async {
    await ref.read(songsListProvider.notifier).loadSongs();
    if (!mounted) return;
    final songs = ref.read(songsListProvider).songs;
    if (songs.isNotEmpty) {
      _lastFocusedSongKey = _songFocusKey(songs.first);
      _focusNodeForSong(songs.first).requestFocus();
    } else {
      _searchFocusNode.requestFocus();
    }
    ResponsiveSnackBar.show(context, message: '歌曲库已刷新');
  }

'''
        text = replace_once(
            text,
            '  PreferredSizeWidget _buildAppBar(BuildContext context, SongsListState state) {',
            insert + '  PreferredSizeWidget _buildAppBar(BuildContext context, SongsListState state) {',
            'library refresh helper',
        )
    text = replace_once(
        text,
        '''          if (AppConfig.isTvMode)
            IconButton(
              icon: const Icon(Icons.search_rounded),''',
        '''          if (AppConfig.isTvMode)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: '刷新歌曲库',
              onPressed: state.isLoading ? null : _refreshTvLibrary,
            ),
          if (AppConfig.isTvMode)
            IconButton(
              icon: const Icon(Icons.search_rounded),''',
        'library TV refresh action',
    )
    write(path, text)


def patch_playlist_page() -> None:
    path = 'lib/features/playlist/presentation/playlists_page.dart'
    text = read(path)
    if "../../../config/app_config.dart" not in text:
        text = replace_once(
            text,
            "import '../../../config/constants.dart';\n",
            "import '../../../config/app_config.dart';\nimport '../../../config/constants.dart';\n",
            'playlist page AppConfig import',
        )
    if "../../../shared/widgets/tv_focusable.dart" not in text:
        text = replace_once(
            text,
            "import '../../../shared/utils/responsive_snackbar.dart';\n",
            "import '../../../shared/utils/responsive_snackbar.dart';\nimport '../../../shared/widgets/tv_focusable.dart';\n",
            'playlist page TvFocusable import',
        )

    text = replace_once(
        text,
        "  final _searchController = TextEditingController();\n",
        '''  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final Map<int, FocusNode> _playlistFocusNodes = {};
  int? _lastFocusedPlaylistId;
''',
        'playlist focus fields',
    )
    text = replace_once(
        text,
        '    _searchController.dispose();\n',
        '''    _searchController.dispose();
    _searchFocusNode.dispose();
    for (final node in _playlistFocusNodes.values) {
      node.dispose();
    }
''',
        'playlist focus dispose',
    )
    helpers_anchor = '  void _onSearchChanged(String value) {'
    helpers = '''  FocusNode _focusNodeForPlaylist(Playlist playlist) {
    return _playlistFocusNodes.putIfAbsent(playlist.id, FocusNode.new);
  }

  Future<void> _submitTvPlaylistSearch(String value) async {
    _onSearchChanged(value);
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (!mounted) return;
    final items = ref.read(playlistListProvider(_selectedType)).value?.items ?? [];
    final results = _filterPlaylists(items);
    if (results.isEmpty) {
      _searchFocusNode.requestFocus();
      return;
    }
    _lastFocusedPlaylistId = results.first.id;
    _focusNodeForPlaylist(results.first).requestFocus();
  }

  Future<void> _refreshTvPlaylists() async {
    ref.invalidate(playlistListProvider(_selectedType));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    ResponsiveSnackBar.show(context, message: '歌单已刷新');
  }

'''
    if 'Future<void> _submitTvPlaylistSearch' not in text:
        text = replace_once(text, helpers_anchor, helpers + helpers_anchor, 'playlist TV helpers')

    text = replace_once(
        text,
        '''      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,''',
        '''      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
        onSubmitted: AppConfig.isTvMode ? _submitTvPlaylistSearch : null,''',
        'playlist search focus and submit',
    )

    text = replace_once(
        text,
        '''      actions: [
        // 视图模式切换按钮''',
        '''      actions: [
        if (AppConfig.isTvMode)
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '刷新歌单',
            onPressed: _refreshTvPlaylists,
          ),
        if (AppConfig.isTvMode)
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: '搜索歌单',
            onPressed: () => _searchFocusNode.requestFocus(),
          ),
        // 视图模式切换按钮''',
        'playlist TV appbar actions',
    )

    for widget_name in ['PlaylistCard', 'PlaylistListItem']:
        old = f'''          return {widget_name}(
            playlist: playlist,
            autofocus: index == 0,'''
        new = f'''          return {widget_name}(
            playlist: playlist,
            focusNode: AppConfig.isTvMode ? _focusNodeForPlaylist(playlist) : null,
            autofocus: AppConfig.isTvMode &&
                (_lastFocusedPlaylistId == null
                    ? index == 0
                    : _lastFocusedPlaylistId == playlist.id),
            onFocusChange: AppConfig.isTvMode
                ? (hasFocus) {{
                    if (hasFocus) _lastFocusedPlaylistId = playlist.id;
                  }}
                : null,'''
        text = replace_once(text, old, new, f'playlist {widget_name} focus memory')

    old_method_start = '  Widget _buildSortModeBody() {'
    start = text.index(old_method_start)
    end = text.index('  AppBar _buildSelectionAppBar(', start)
    old_method = text[start:end]
    new_method = '''  void _moveSortablePlaylist(int index, int delta) {
    final target = (index + delta).clamp(0, _sortablePlaylists.length - 1);
    if (target == index) return;
    setState(() {
      final item = _sortablePlaylists.removeAt(index);
      _sortablePlaylists.insert(target, item);
    });
  }

  Widget _buildSortModeBody() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_sortablePlaylists.isEmpty) {
      return const Center(child: Text('暂无歌单'));
    }

    if (AppConfig.isTvMode) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        itemCount: _sortablePlaylists.length,
        itemBuilder: (context, index) {
          final playlist = _sortablePlaylists[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TvFocusable(
              autofocus: index == 0,
              onSelect: () {},
              onKeyEvent: (_, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  _moveSortablePlaylist(index, -1);
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  _moveSortablePlaylist(index, 1);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              focusedScale: 1.015,
              borderRadius: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${index + 1}',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        playlist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '← 前移   后移 →',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _sortablePlaylists.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final playlist = _sortablePlaylists[index];
        return Card(
          key: ValueKey(playlist.id),
          child: ListTile(
            leading: SizedBox(
              width: 32,
              child: Text('${index + 1}', textAlign: TextAlign.center),
            ),
            title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${playlist.songCount} 首歌曲'),
            trailing: ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle, color: colorScheme.onSurfaceVariant),
            ),
          ),
        );
      },
    );
  }

'''
    text = text[:start] + new_method + text[end:]

    text = text.replace(
        '''              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),''',
        '''              TextButton(
                autofocus: AppConfig.isTvMode,
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),''',
    )
    write(path, text)


def patch_playlist_widget_focus_fields() -> None:
    for path in [
        'lib/features/playlist/presentation/widgets/playlist_card.dart',
        'lib/features/playlist/presentation/widgets/playlist_list_item.dart',
    ]:
        text = read(path)
        if 'final FocusNode? focusNode;' not in text:
            text = replace_once(
                text,
                '  final bool autofocus;\n',
                '''  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
''',
                f'{path} focus fields',
            )
            text = replace_once(
                text,
                '    this.autofocus = false,\n  });',
                '''    this.autofocus = false,
    this.focusNode,
    this.onFocusChange,
  });''',
                f'{path} focus constructor',
            )
        text = replace_once(
            text,
            '      autofocus: autofocus,\n      onSelect: action,',
            '''      autofocus: autofocus,
      focusNode: focusNode,
      onFocusChange: onFocusChange,
      onSelect: action,''',
            f'{path} focus forwarding',
        )
        write(path, text)


def patch_playlist_detail() -> None:
    path = 'lib/features/playlist/presentation/playlist_detail_page.dart'
    text = read(path)
    if 'void _moveSortableSong(' not in text:
        text = replace_once(
            text,
            '  void _onReorder(int oldIndex, int newIndex) {',
            '''  void _moveSortableSong(int index, int delta) {
    final target = (index + delta).clamp(0, _sortableSongs.length - 1);
    if (target == index) return;
    setState(() {
      final item = _sortableSongs.removeAt(index);
      _sortableSongs.insert(target, item);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {''',
            'playlist detail TV sort helper',
        )

    old_sort_block = '''    if (_isSortMode) {
      return SliverToBoxAdapter(
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _sortableSongs.length,
          onReorder: _onReorder,
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
'''
    new_sort_block = '''    if (_isSortMode) {
      if (AppConfig.isTvMode) {
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final song = _sortableSongs[index];
            return TvFocusable(
              autofocus: index == 0,
              onSelect: () {},
              onKeyEvent: (_, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  _moveSortableSong(index, -1);
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  _moveSortableSong(index, 1);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              focusedScale: 1.012,
              borderRadius: 16,
              child: _PlaylistSongTile(
                song: song,
                index: index,
                displayIndex: index + 1,
                isCurrent: currentSong?.id == song.id,
                showDragHandle: false,
                onTap: () {},
              ),
            );
          }, childCount: _sortableSongs.length),
        );
      }

      return SliverToBoxAdapter(
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _sortableSongs.length,
          onReorder: _onReorder,
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
'''
    text = replace_once(text, old_sort_block, new_sort_block, 'playlist detail TV sort mode')
    text = text.replace(
        '''              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),''',
        '''              TextButton(
                autofocus: AppConfig.isTvMode,
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),''',
    )
    write(path, text)


def patch_delete_dialog() -> None:
    path = 'lib/shared/widgets/delete_song_dialog.dart'
    text = read(path)
    if "../../config/app_config.dart" not in text:
        text = replace_once(
            text,
            "import '../../core/theme/responsive.dart';\n",
            "import '../../config/app_config.dart';\nimport '../../core/theme/responsive.dart';\n",
            'delete dialog AppConfig import',
        )
    text = replace_once(
        text,
        '''        TextButton(
          onPressed: () => Navigator.of(context).pop(),''',
        '''        TextButton(
          autofocus: AppConfig.isTvMode,
          onPressed: () => Navigator.of(context).pop(),''',
        'delete dialog cancel focus',
    )
    write(path, text)


def main() -> None:
    patch_tv_focusable()
    patch_adaptive_scaffold()
    patch_song_list_tile()
    patch_playlist_widgets()
    patch_playlist_drawer()
    patch_tv_player()
    patch_library_page()
    patch_playlist_widget_focus_fields()
    patch_playlist_page()
    patch_playlist_detail()
    patch_delete_dialog()
    print('TV release polish applied')


if __name__ == '__main__':
    main()
