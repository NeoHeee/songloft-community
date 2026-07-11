from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f"missing patch anchor: {label}")
    return text.replace(old, new, 1)


def patch_tv_focusable() -> None:
    path = "lib/shared/widgets/tv_focusable.dart"
    text = read(path)
    if "final KeyEventResult Function(FocusNode node, KeyEvent event)? onKeyEvent;" in text:
        return

    text = replace_once(
        text,
        "  /// 获得焦点时自动滚动到可视区域\n  final bool scrollIntoView;\n",
        "  /// 获得焦点时自动滚动到可视区域\n"
        "  final bool scrollIntoView;\n\n"
        "  /// 自定义按键处理，优先于默认确认键逻辑\n"
        "  final KeyEventResult Function(FocusNode node, KeyEvent event)? onKeyEvent;\n",
        "TvFocusable custom key field",
    )
    text = replace_once(
        text,
        "    this.onFocusChange,\n    this.scrollIntoView = true,\n  });",
        "    this.onFocusChange,\n"
        "    this.scrollIntoView = true,\n"
        "    this.onKeyEvent,\n"
        "  });",
        "TvFocusable custom key constructor",
    )
    text = replace_once(
        text,
        "  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {\n"
        "    if (!widget.enabled || widget.onSelect == null) {\n"
        "      return KeyEventResult.ignored;\n"
        "    }\n",
        "  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {\n"
        "    final customResult = widget.onKeyEvent?.call(node, event);\n"
        "    if (customResult != null && customResult != KeyEventResult.ignored) {\n"
        "      return customResult;\n"
        "    }\n\n"
        "    if (!widget.enabled || widget.onSelect == null) {\n"
        "      return KeyEventResult.ignored;\n"
        "    }\n",
        "TvFocusable custom key handler",
    )
    write(path, text)


def patch_player_provider() -> None:
    path = "lib/features/player/presentation/providers/player_provider.dart"
    text = read(path)
    if "Future<void> queueNext(Song song)" in text:
        return

    anchor = "  /// 将歌曲插入到播放列表的指定位置\n"
    method = r'''  /// 将歌曲安排为下一首播放。
  ///
  /// 若歌曲已在队列中，会先移动到当前歌曲之后，避免重复条目；
  /// 当前没有播放内容时则直接开始播放该歌曲。
  Future<void> queueNext(Song song) async {
    if (!state.hasSong || state.currentIndex < 0 || state.playlist.isEmpty) {
      await playSong(song);
      return;
    }

    final newPlaylist = List<Song>.from(state.playlist);
    var currentIndex = state.currentIndex;
    final existingIndex = newPlaylist.indexWhere(
      (item) => item.id == song.id && item.type == song.type,
    );

    if (existingIndex == currentIndex) return;
    if (existingIndex >= 0) {
      newPlaylist.removeAt(existingIndex);
      if (existingIndex < currentIndex) currentIndex--;
    }

    final insertIndex = (currentIndex + 1).clamp(0, newPlaylist.length);
    newPlaylist.insert(insertIndex, song);
    state = state.copyWith(
      playlist: newPlaylist,
      currentIndex: currentIndex,
      currentSong: newPlaylist[currentIndex],
    );
    _savePlaybackState();
  }

'''
    text = replace_once(text, anchor, method + anchor, "queueNext insertion")
    write(path, text)


def patch_song_list_tile() -> None:
    path = "lib/features/library/presentation/widgets/song_list_tile.dart"
    text = read(path)
    if "final VoidCallback? onPlayNext;" in text:
        return

    text = replace_once(
        text,
        "import 'package:flutter/material.dart';\n",
        "import 'package:flutter/material.dart';\n"
        "import 'package:flutter/services.dart';\n",
        "SongListTile services import",
    )
    text = replace_once(
        text,
        "import '../../../../shared/widgets/tv_focusable.dart';",
        "import '../../../../shared/widgets/tv_action_dialog.dart';\n"
        "import '../../../../shared/widgets/tv_focusable.dart';",
        "SongListTile action dialog import",
    )
    text = replace_once(
        text,
        "  final VoidCallback? onAddToPlaylist;\n",
        "  final VoidCallback? onAddToPlaylist;\n"
        "  final VoidCallback? onPlayNext;\n"
        "  final VoidCallback? onAddToQueue;\n"
        "  final FocusNode? focusNode;\n"
        "  final bool autofocus;\n"
        "  final ValueChanged<bool>? onFocusChange;\n",
        "SongListTile TV fields",
    )
    text = replace_once(
        text,
        "    this.onEdit,\n    this.onAddToPlaylist,\n  });",
        "    this.onEdit,\n"
        "    this.onAddToPlaylist,\n"
        "    this.onPlayNext,\n"
        "    this.onAddToQueue,\n"
        "    this.focusNode,\n"
        "    this.autofocus = false,\n"
        "    this.onFocusChange,\n"
        "  });",
        "SongListTile TV constructor",
    )
    text = replace_once(
        text,
        "    return TvFocusable(\n"
        "      autofocus: index == 0,\n"
        "      onSelect: action,",
        "    return TvFocusable(\n"
        "      autofocus: autofocus,\n"
        "      focusNode: focusNode,\n"
        "      onFocusChange: onFocusChange,\n"
        "      onKeyEvent: (node, event) => _handleTvKey(context, ref, event),\n"
        "      onSelect: action,",
        "SongListTile TV wrapper",
    )

    insertion = r'''
  KeyEventResult _handleTvKey(
    BuildContext context,
    WidgetRef ref,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent || isSelectionMode) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.contextMenu ||
        key == LogicalKeyboardKey.gameButtonY ||
        key == LogicalKeyboardKey.keyM ||
        key == LogicalKeyboardKey.delete) {
      _showTvActions(context, ref);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _showTvActions(BuildContext context, WidgetRef ref) {
    showTvActionDialog(
      context: context,
      title: song.title,
      actions: [
        if (onTap != null)
          TvActionItem(
            icon: Icons.play_arrow_rounded,
            label: '立即播放',
            onPressed: onTap!,
          ),
        if (onPlayNext != null)
          TvActionItem(
            icon: Icons.skip_next_rounded,
            label: '下一首播放',
            onPressed: onPlayNext!,
          ),
        if (onAddToQueue != null)
          TvActionItem(
            icon: Icons.queue_music_rounded,
            label: '加入播放队列',
            onPressed: onAddToQueue!,
          ),
        if (onAddToPlaylist != null)
          TvActionItem(
            icon: Icons.playlist_add_rounded,
            label: '加入歌单',
            onPressed: onAddToPlaylist!,
          ),
        if (onEdit != null)
          TvActionItem(
            icon: Icons.edit_rounded,
            label: '编辑歌曲',
            onPressed: onEdit!,
          ),
        if (onDelete != null)
          TvActionItem(
            icon: Icons.delete_outline_rounded,
            label: '删除歌曲',
            onPressed: onDelete!,
            destructive: true,
          ),
      ],
    );
  }
'''
    anchor = "\n  Widget _buildMobileLayout(BuildContext context) {"
    text = replace_once(text, anchor, insertion + anchor, "SongListTile TV actions")
    write(path, text)


def patch_library_page() -> None:
    path = "lib/features/library/presentation/library_page.dart"
    text = read(path)
    if "final _searchFocusNode = FocusNode();" in text:
        return

    text = replace_once(
        text,
        "import '../../../config/constants.dart';",
        "import '../../../config/app_config.dart';\n"
        "import '../../../config/constants.dart';",
        "Library AppConfig import",
    )
    text = replace_once(
        text,
        "  final _searchController = TextEditingController();\n"
        "  Timer? _debounceTimer;",
        "  final _searchController = TextEditingController();\n"
        "  final _searchFocusNode = FocusNode();\n"
        "  final Map<String, FocusNode> _songFocusNodes = {};\n"
        "  String? _lastFocusedSongKey;\n"
        "  Timer? _debounceTimer;",
        "Library focus fields",
    )
    text = replace_once(
        text,
        "    _searchController.dispose();\n"
        "    _debounceTimer?.cancel();",
        "    _searchController.dispose();\n"
        "    _searchFocusNode.dispose();\n"
        "    for (final node in _songFocusNodes.values) {\n"
        "      node.dispose();\n"
        "    }\n"
        "    _debounceTimer?.cancel();",
        "Library focus dispose",
    )

    helper_anchor = "  Future<void> _playAll(SongsListState state) async {"
    helpers = r'''  String _songFocusKey(Song song) => '${song.type}:${song.id}';

  FocusNode _focusNodeForSong(Song song) {
    return _songFocusNodes.putIfAbsent(_songFocusKey(song), FocusNode.new);
  }

  Future<void> _submitTvSearch(String value) async {
    _debounceTimer?.cancel();
    await ref.read(songsListProvider.notifier).search(value);
    if (!mounted || !AppConfig.isTvMode) return;

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    final songs = ref.read(songsListProvider).songs;
    if (songs.isEmpty) {
      _searchFocusNode.requestFocus();
      return;
    }
    _lastFocusedSongKey = _songFocusKey(songs.first);
    _focusNodeForSong(songs.first).requestFocus();
  }

  void _queueSongNext(Song song) {
    ref.read(playerStateProvider.notifier).queueNext(song);
    ResponsiveSnackBar.show(context, message: '已将「${song.title}」设为下一首');
  }

  void _addSongToQueue(Song song) {
    ref.read(playerStateProvider.notifier).addToPlaylist([song]);
    ResponsiveSnackBar.show(context, message: '已加入播放队列：${song.title}');
  }

'''
    text = replace_once(text, helper_anchor, helpers + helper_anchor, "Library TV helpers")

    text = replace_once(
        text,
        "        actions: [\n"
        "          IconButton(\n"
        "            icon: const Icon(Icons.checklist_rounded),",
        "        actions: [\n"
        "          if (AppConfig.isTvMode)\n"
        "            IconButton(\n"
        "              icon: const Icon(Icons.search_rounded),\n"
        "              tooltip: '搜索歌曲',\n"
        "              onPressed: () => _searchFocusNode.requestFocus(),\n"
        "            ),\n"
        "          IconButton(\n"
        "            icon: const Icon(Icons.checklist_rounded),",
        "Library TV search action",
    )
    text = replace_once(
        text,
        "    return TextField(\n"
        "      controller: _searchController,",
        "    return TextField(\n"
        "      controller: _searchController,\n"
        "      focusNode: _searchFocusNode,\n"
        "      textInputAction: TextInputAction.search,",
        "Library search focus",
    )
    text = replace_once(
        text,
        "                    ref.read(songsListProvider.notifier).search('');\n"
        "                  },",
        "                    ref.read(songsListProvider.notifier).search('');\n"
        "                    _searchFocusNode.requestFocus();\n"
        "                  },",
        "Library clear search focus",
    )
    text = replace_once(
        text,
        "      onChanged: _onSearchChanged,\n"
        "    );",
        "      onChanged: _onSearchChanged,\n"
        "      onSubmitted: AppConfig.isTvMode ? _submitTvSearch : null,\n"
        "    );",
        "Library search submit",
    )

    def patch_tile(block: str, label: str) -> str:
        old = """          onTap: () => _onSongTap(song, index),
          onLongPress: () {
"""
        new = """          focusNode: AppConfig.isTvMode ? _focusNodeForSong(song) : null,
          autofocus: AppConfig.isTvMode &&
              (_lastFocusedSongKey == null
                  ? index == 0
                  : _lastFocusedSongKey == _songFocusKey(song)),
          onFocusChange: AppConfig.isTvMode
              ? (hasFocus) {
                  if (hasFocus) {
                    _lastFocusedSongKey = _songFocusKey(song);
                  }
                }
              : null,
          onTap: () => _onSongTap(song, index),
          onPlayNext: () => _queueSongNext(song),
          onAddToQueue: () => _addSongToQueue(song),
          onLongPress: () {
"""
        if old not in block:
            raise RuntimeError(f"missing patch anchor: {label}")
        return block.replace(old, new, 1)

    # Apply to mobile and desktop SongListTile blocks independently.
    first_pos = text.index("        return SongListTile(")
    second_pos = text.index("                      return SongListTile(", first_pos + 1)
    first_end = text.index("        );", first_pos) + len("        );")
    first_block = text[first_pos:first_end]
    text = text[:first_pos] + patch_tile(first_block, "Library mobile tile") + text[first_end:]

    # Recompute after first replacement.
    second_pos = text.index("                      return SongListTile(", first_pos + 1)
    second_end = text.index("                      );", second_pos) + len("                      );")
    second_block = text[second_pos:second_end]
    text = text[:second_pos] + patch_tile(second_block, "Library desktop tile") + text[second_end:]

    write(path, text)


def main() -> None:
    patch_tv_focusable()
    patch_player_provider()
    patch_song_list_tile()
    patch_library_page()
    print("TV round-three patch applied")


if __name__ == "__main__":
    main()
