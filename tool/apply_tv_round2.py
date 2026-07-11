from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    (ROOT / path).write_text(content, encoding="utf-8")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f"missing patch anchor: {label}")
    return text.replace(old, new, 1)


def patch_settings_master_detail() -> None:
    path = "lib/features/settings/presentation/widgets/settings_master_detail.dart"
    text = read(path)
    if "Widget _buildTvLayout" in text:
        return

    text = replace_once(
        text,
        "import '../../../../core/theme/responsive.dart';",
        "import '../../../../core/theme/responsive.dart';\n"
        "import '../../../../core/theme/tv_theme.dart';\n"
        "import '../../../../shared/widgets/tv_focusable.dart';",
        "settings TV imports",
    )

    text = replace_once(
        text,
        "  Widget build(BuildContext context) {\n"
        "    if (context.isWideScreen && !context.isTv && !context.isAuto) {",
        "  Widget build(BuildContext context) {\n"
        "    if (context.isTv) {\n"
        "      return _buildTvLayout(context);\n"
        "    }\n"
        "    if (context.isWideScreen && !context.isAuto) {",
        "settings TV layout switch",
    )

    insert_before = "  Widget _buildMobileLayout(BuildContext context) {"
    tv_layout = r'''  Widget _buildTvLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            TvTheme.contentPadding,
            TvTheme.spacingLarge,
            TvTheme.contentPadding,
            TvTheme.spacingMedium,
          ),
          sliver: SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (header != null) ...[
                    FocusTraversalGroup(child: header!),
                    const SizedBox(height: TvTheme.spacingLarge),
                  ],
                  Text(
                    '设置分类',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '使用方向键选择分类，按确认键进入',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            TvTheme.contentPadding,
            0,
            TvTheme.contentPadding,
            120,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 2.45,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final category = categories[index];
              return TvFocusable(
                autofocus: index == selectedIndex,
                onSelect: () => onCategorySelected(index),
                focusedScale: 1.025,
                borderRadius: 22,
                child: _TvCategoryCard(
                  category: category,
                  selected: index == selectedIndex,
                ),
              );
            }, childCount: categories.length),
          ),
        ),
      ],
    );
  }

'''
    text = replace_once(text, insert_before, tv_layout + insert_before, "insert TV settings layout")

    class_anchor = "class _CategoryItem extends StatelessWidget {"
    tv_card = r'''class _TvCategoryCard extends StatelessWidget {
  final SettingsCategory category;
  final bool selected;

  const _TvCategoryCard({required this.category, required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: TvTheme.focusAnimationDuration,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.7)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.45)
              : colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.16)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              category.icon,
              size: 30,
              color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  category.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
        ],
      ),
    );
  }
}

'''
    text = replace_once(text, class_anchor, tv_card + class_anchor, "insert TV category card")
    write(path, text)


def patch_settings_page() -> None:
    path = "lib/features/settings/presentation/settings_page.dart"
    text = read(path)
    if "使用方向键浏览本页设置" in text:
        return

    text = replace_once(
        text,
        "    final isMobile = !context.isWideScreen || context.isTv;",
        "    final isTv = context.isTv;\n"
        "    final isMobile = !context.isWideScreen || isTv;",
        "settings isTv flag",
    )

    old_appbar = r'''          appBar: AppBar(
            leading: BackButton(
              onPressed: () => setState(() => _mobileDetailIndex = null),
            ),
            title: Text(category.title),
          ),
          body: _buildCategoryContent(_mobileDetailIndex!),
'''
    new_appbar = r'''          appBar: AppBar(
            toolbarHeight: isTv ? 76 : null,
            leading: IconButton(
              autofocus: isTv,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: '返回设置分类',
              onPressed: () => setState(() => _mobileDetailIndex = null),
            ),
            title: Text(
              category.title,
              style: isTv
                  ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    )
                  : null,
            ),
            bottom: isTv
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(34),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '使用方向键浏览本页设置，按返回键回到分类',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                : null,
          ),
          body: FocusTraversalGroup(
            child: _buildCategoryContent(_mobileDetailIndex!),
          ),
'''
    text = replace_once(text, old_appbar, new_appbar, "settings TV detail appbar")

    text = replace_once(
        text,
        "    final settingsScaffold = Scaffold(\n"
        "      appBar: AppBar(title: const Text('设置')),",
        "    final settingsScaffold = Scaffold(\n"
        "      appBar: AppBar(\n"
        "        toolbarHeight: isTv ? 72 : null,\n"
        "        title: Text(\n"
        "          '设置',\n"
        "          style: isTv\n"
        "              ? Theme.of(context).textTheme.headlineSmall?.copyWith(\n"
        "                  fontWeight: FontWeight.w800,\n"
        "                )\n"
        "              : null,\n"
        "        ),\n"
        "      ),",
        "settings TV root appbar",
    )

    old_content = r'''    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: _interleave(items, const SizedBox(height: AppSpacing.lg)),
    );
'''
    new_content = r'''    final list = ListView(
      padding: EdgeInsets.fromLTRB(
        context.isTv ? AppSpacing.xxl : AppSpacing.md,
        AppSpacing.md,
        context.isTv ? AppSpacing.xxl : AppSpacing.md,
        context.isTv ? 120 : AppSpacing.md,
      ),
      children: _interleave(items, const SizedBox(height: AppSpacing.lg)),
    );

    if (!context.isTv) return list;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Scrollbar(child: list),
      ),
    );
'''
    text = replace_once(text, old_content, new_content, "settings TV content width")
    write(path, text)


def patch_tv_player() -> None:
    path = "lib/features/player/presentation/widgets/tv_player.dart"
    text = read(path)
    if "媒体播放键：播放/暂停" in text:
        return

    widget_anchor = r'''class TvPlayer extends ConsumerStatefulWidget {
  const TvPlayer({super.key});

  @override
'''
    widget_new = r'''class TvPlayer extends ConsumerStatefulWidget {
  const TvPlayer({super.key});

  static Future<void> show(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final notifier = container.read(playerStateProvider.notifier);
    final state = container.read(playerStateProvider);
    if (!state.showFullPlayer) notifier.toggleFullPlayer();

    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (_, _, _) => const TvPlayer(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 140),
      ),
    );
    notifier.closeFullPlayer();
  }

  @override
'''
    text = replace_once(text, widget_anchor, widget_new, "TvPlayer show method")

    text = replace_once(
        text,
        "class _TvPlayerState extends ConsumerState<TvPlayer> {\n"
        "  final _playlistButtonFocusNode = FocusNode();",
        "class _TvPlayerState extends ConsumerState<TvPlayer> {\n"
        "  final _playlistButtonFocusNode = FocusNode();\n"
        "  final _playModeButtonFocusNode = FocusNode();",
        "TvPlayer focus nodes",
    )
    text = replace_once(
        text,
        "  void dispose() {\n"
        "    _playlistButtonFocusNode.dispose();",
        "  void dispose() {\n"
        "    _playlistButtonFocusNode.dispose();\n"
        "    _playModeButtonFocusNode.dispose();",
        "TvPlayer dispose focus node",
    )

    build_anchor = "  @override\n  Widget build(BuildContext context) {"
    key_handler = r'''  KeyEventResult _handleRemoteKey(
    KeyEvent event,
    PlayerState state,
    PlayerNotifier notifier,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.mediaPlayPause) {
      notifier.togglePlay();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaPlay && !state.isPlaying) {
      notifier.togglePlay();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaPause && state.isPlaying) {
      notifier.togglePlay();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaTrackNext && state.hasNext) {
      notifier.playNext();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaTrackPrevious && state.hasPrev) {
      notifier.playPrev();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.audioVolumeDown) {
      notifier.setVolume((state.volume - 10).clamp(0.0, 100.0));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.audioVolumeUp) {
      notifier.setVolume((state.volume + 10).clamp(0.0, 100.0));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

'''
    text = replace_once(text, build_anchor, key_handler + build_anchor, "TvPlayer remote handler")

    text = replace_once(
        text,
        "    return Scaffold(\n      body: Container(",
        "    return Focus(\n"
        "      canRequestFocus: false,\n"
        "      onKeyEvent: (_, event) => _handleRemoteKey(event, state, notifier),\n"
        "      child: Scaffold(\n"
        "        body: Container(",
        "TvPlayer root key listener",
    )

    old_build_end = """        ),
      ),
    );
  }

  /// 顶部工具栏
"""
    new_build_end = """          ),
        ),
      ),
    );
  }

  /// 顶部工具栏
"""
    text = replace_once(text, old_build_end, new_build_end, "TvPlayer root closing")

    text = replace_once(
        text,
        "      padding: const EdgeInsets.symmetric(\n"
        "        horizontal: TvTheme.contentPadding,\n"
        "        vertical: TvTheme.spacingMedium,\n"
        "      ),",
        "      padding: EdgeInsets.symmetric(\n"
        "        horizontal: TvTheme.contentPadding,\n"
        "        vertical: MediaQuery.sizeOf(context).height < 780\n"
        "            ? TvTheme.spacingSmall\n"
        "            : TvTheme.spacingMedium,\n"
        "      ),",
        "TvPlayer compact topbar",
    )

    text = replace_once(
        text,
        "    return Container(\n      width: 360,\n      height: 360,",
        "    final compact = MediaQuery.sizeOf(context).height < 780;\n"
        "    final coverSize = compact ? 250.0 : 360.0;\n\n"
        "    return Container(\n"
        "      width: coverSize,\n"
        "      height: coverSize,",
        "TvPlayer compact cover",
    )

    text = replace_once(
        text,
        "                 child: Row(\n                   mainAxisAlignment: MainAxisAlignment.center,",
        "                 child: FittedBox(\n"
        "                   fit: BoxFit.scaleDown,\n"
        "                   child: Row(\n"
        "                     mainAxisAlignment: MainAxisAlignment.center,",
        "TvPlayer controls FittedBox open",
    )
    text = replace_once(
        text,
        "           ],\n         ),\n       ),\n     );\n   }\n\n   /// 播放/暂停按钮",
        "           ],\n"
        "                   ),\n"
        "                 ),\n"
        "       ),\n"
        "     );\n"
        "   }\n\n"
        "   /// 播放/暂停按钮",
        "TvPlayer controls FittedBox close",
    )

    text = replace_once(
        text,
        "                 (buttonContext) => _TvPlayerControlButton(\n"
        "                   icon: _getPlayModeIcon(state.playMode),",
        "                 (buttonContext) => _TvPlayerControlButton(\n"
        "                   icon: _getPlayModeIcon(state.playMode),\n"
        "                   focusNode: _playModeButtonFocusNode,",
        "TvPlayer play mode focus node",
    )

    old_overlay_callbacks = r'''    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder:
          (context) => _TvPlayModeOverlayPanel(
            playMode: state.playMode,
            onPlayModeChanged: (mode) {
              notifier.setPlayMode(mode);
              overlayEntry.remove();
            },
            onDismiss: () => overlayEntry.remove(),
'''
    new_overlay_callbacks = r'''    late OverlayEntry overlayEntry;
    var removed = false;
    void closeOverlay() {
      if (removed) return;
      removed = true;
      overlayEntry.remove();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playModeButtonFocusNode.requestFocus();
      });
    }

    overlayEntry = OverlayEntry(
      builder:
          (context) => _TvPlayModeOverlayPanel(
            playMode: state.playMode,
            onPlayModeChanged: (mode) {
              notifier.setPlayMode(mode);
              closeOverlay();
            },
            onDismiss: closeOverlay,
'''
    text = replace_once(text, old_overlay_callbacks, new_overlay_callbacks, "play mode focus restore")

    text = replace_once(
        text,
        "    return Stack(\n      children: [",
        "    return Focus(\n"
        "      canRequestFocus: false,\n"
        "      onKeyEvent: (_, event) {\n"
        "        if (event is KeyDownEvent &&\n"
        "            (event.logicalKey == LogicalKeyboardKey.escape ||\n"
        "                event.logicalKey == LogicalKeyboardKey.goBack)) {\n"
        "          onDismiss();\n"
        "          return KeyEventResult.handled;\n"
        "        }\n"
        "        return KeyEventResult.ignored;\n"
        "      },\n"
        "      child: Stack(\n"
        "        children: [",
        "play mode overlay back handler",
    )
    text = replace_once(
        text,
        "      ],\n    );\n  }\n}\n\n/// TV 迷你播放器",
        "        ],\n"
        "      ),\n"
        "    );\n"
        "  }\n"
        "}\n\n"
        "/// TV 迷你播放器",
        "play mode overlay close focus",
    )
    text = replace_once(
        text,
        "                             (itemContext) => TvFocusable(\n"
        "                               onSelect: () => onPlayModeChanged(mode),",
        "                             (itemContext) => TvFocusable(\n"
        "                               autofocus: mode == playMode,\n"
        "                               onSelect: () => onPlayModeChanged(mode),",
        "play mode selected autofocus",
    )

    mini_start = text.index("               // 封面\n", text.index("class TvMiniPlayer"))
    mini_end = text.index("               // 播放控制\n", mini_start)
    old_mini_info = text[mini_start:mini_end]
    new_mini_info = r'''               // 点击歌曲信息进入 TV 全屏播放器
               Expanded(
                 child: TvFocusable(
                   onSelect: () => TvPlayer.show(context),
                   focusedScale: 1.015,
                   borderRadius: 14,
                   child: Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 8),
                     child: Row(
                       children: [
                         Container(
                           width: 56,
                           height: 56,
                           decoration: BoxDecoration(
                             borderRadius: BorderRadius.circular(8),
                             color: theme.colorScheme.surfaceContainerHighest,
                           ),
                           clipBehavior: Clip.antiAlias,
                           child: coverUrl != null
                               ? ExcludeSemantics(
                                   child: Image.network(
                                     UrlHelper.buildCoverUrl(coverUrl),
                                     fit: BoxFit.cover,
                                   ),
                                 )
                               : Icon(
                                   Icons.music_note_rounded,
                                   color: theme.colorScheme.onSurfaceVariant,
                                 ),
                         ),
                         const SizedBox(width: TvTheme.spacingMedium),
                         Expanded(
                           child: Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 song.title,
                                 style: TvTheme.bodyStyle(context).copyWith(
                                   fontWeight: FontWeight.w500,
                                 ),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               ),
                               const SizedBox(height: 4),
                               Text(
                                 '${song.artist ?? '未知艺术家'} · 按确认键展开播放器',
                                 style: TvTheme.captionStyle(context),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ],
                           ),
                         ),
                       ],
                     ),
                   ),
                 ),
               ),
               const SizedBox(width: TvTheme.spacingMedium),
'''
    text = text[:mini_start] + new_mini_info + text[mini_end:]

    # Marker used to keep the patch idempotent and describe remote support.
    text = text.replace(
        "/// - 渐变背景\nclass TvPlayer",
        "/// - 渐变背景\n"
        "/// - 媒体播放键：播放/暂停、切歌和音量控制\n"
        "class TvPlayer",
        1,
    )
    write(path, text)


def main() -> None:
    patch_settings_master_detail()
    patch_settings_page()
    patch_tv_player()
    print("TV round-two patch applied")


if __name__ == "__main__":
    main()
