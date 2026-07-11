from pathlib import Path
import re


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: expected one match, found {count}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


def patch_shell_layout() -> None:
    path = Path("lib/shared/layouts/shell_layout.dart")
    text = path.read_text(encoding="utf-8")

    text = text.replace(
        "    final routerCanPop = GoRouter.of(context).canPop();\n"
        "    final childHandlesBack = location == '/settings';\n",
        "    final routerCanPop = GoRouter.of(context).canPop();\n"
        "    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;\n"
        "    final childHandlesBack = location == '/settings';\n",
        1,
    )

    text = text.replace(
        "      canPop: !showPlaylistDrawer && (routerCanPop || childHandlesBack),\n",
        "      canPop:\n"
        "          !keyboardVisible &&\n"
        "          !showPlaylistDrawer &&\n"
        "          (routerCanPop || childHandlesBack),\n",
        1,
    )

    text = text.replace(
        "        if (didPop) return;\n\n"
        "        if (showPlaylistDrawer) {\n",
        "        if (didPop) return;\n\n"
        "        if (keyboardVisible) {\n"
        "          FocusManager.instance.primaryFocus?.unfocus();\n"
        "          return;\n"
        "        }\n\n"
        "        if (showPlaylistDrawer) {\n",
        1,
    )

    text = text.replace(
        "      context.go('/');\n",
        "      HapticFeedback.selectionClick();\n"
        "      context.go('/');\n",
        1,
    )

    text = text.replace(
        "      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {\n"
        "        SystemNavigator.pop();\n",
        "      HapticFeedback.mediumImpact();\n"
        "      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {\n"
        "        SystemNavigator.pop();\n",
        1,
    )

    text = text.replace(
        "    _lastBackPressedAt = now;\n"
        "    messenger.showSnackBar(\n",
        "    _lastBackPressedAt = now;\n"
        "    HapticFeedback.selectionClick();\n"
        "    messenger.showSnackBar(\n",
        1,
    )

    path.write_text(text, encoding="utf-8")


def patch_mobile_player() -> None:
    path = Path("lib/features/player/presentation/widgets/mobile_player.dart")
    text = path.read_text(encoding="utf-8")

    if "package:flutter/services.dart" not in text:
        text = text.replace(
            "import 'package:flutter/material.dart';\n",
            "import 'package:flutter/material.dart';\n"
            "import 'package:flutter/services.dart';\n",
            1,
        )

    text = text.replace(
        "  int _currentPage = 0;\n"
        "  double _dragOffset = 0;\n"
        "  bool _isDragging = false;\n",
        "  static const double _dismissDistance = 110;\n\n"
        "  int _currentPage = 0;\n"
        "  double _dragOffset = 0;\n"
        "  bool _isDragging = false;\n"
        "  bool _canDismissFromStart = false;\n"
        "  bool _dismissHapticTriggered = false;\n",
        1,
    )

    old_methods = '''  void _handleVerticalDragStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details, double maxOffset) {
    final next = (_dragOffset + details.delta.dy).clamp(0.0, maxOffset);
    if (next != _dragOffset) {
      setState(() => _dragOffset = next.toDouble());
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldClose = _dragOffset > 110 || velocity > 700;
    if (shouldClose) {
      _closePlayer();
      return;
    }
    setState(() {
      _isDragging = false;
      _dragOffset = 0;
    });
  }
'''
    new_methods = '''  void _handleVerticalDragStart(
    DragStartDetails details,
    double maxStartY,
  ) {
    _canDismissFromStart =
        _currentPage == 0 && details.localPosition.dy <= maxStartY;
    if (!_canDismissFromStart) return;

    _dismissHapticTriggered = false;
    setState(() => _isDragging = true);
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details, double maxOffset) {
    if (!_canDismissFromStart) return;

    final next = (_dragOffset + details.delta.dy).clamp(0.0, maxOffset);
    if (!_dismissHapticTriggered && next >= _dismissDistance) {
      _dismissHapticTriggered = true;
      HapticFeedback.selectionClick();
    } else if (_dismissHapticTriggered && next < _dismissDistance) {
      _dismissHapticTriggered = false;
    }

    if (next != _dragOffset) {
      setState(() => _dragOffset = next.toDouble());
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (!_canDismissFromStart) return;

    final velocity = details.primaryVelocity ?? 0;
    final shouldClose = _dragOffset >= _dismissDistance || velocity > 700;
    _canDismissFromStart = false;

    if (shouldClose) {
      HapticFeedback.lightImpact();
      _closePlayer();
      return;
    }
    _resetDismissGesture();
  }

  void _handleVerticalDragCancel() {
    if (!_canDismissFromStart && !_isDragging) return;
    _resetDismissGesture();
  }

  void _resetDismissGesture() {
    _canDismissFromStart = false;
    _dismissHapticTriggered = false;
    setState(() {
      _isDragging = false;
      _dragOffset = 0;
    });
  }
'''
    if old_methods not in text:
        raise RuntimeError("mobile player drag methods not found")
    text = text.replace(old_methods, new_methods, 1)

    old_return = '''    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: _handleVerticalDragStart,
      onVerticalDragUpdate:
          (details) => _handleVerticalDragUpdate(details, size.height * 0.45),
      onVerticalDragEnd: _handleVerticalDragEnd,
      child: AnimatedContainer(
        duration:
            _isDragging ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _dragOffset, 0),
        child: Scaffold(
'''
    new_return = '''    final dismissGestureEnabled = _currentPage == 0;
    final dragProgress = (_dragOffset / (size.height * 0.35)).clamp(0.0, 1.0);
    final dragScale = 1 - dragProgress * 0.035;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(playerStateProvider.notifier).closeFullPlayer();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart:
            dismissGestureEnabled
                ? (details) => _handleVerticalDragStart(
                  details,
                  size.height * 0.62,
                )
                : null,
        onVerticalDragUpdate:
            dismissGestureEnabled
                ? (details) =>
                    _handleVerticalDragUpdate(details, size.height * 0.45)
                : null,
        onVerticalDragEnd:
            dismissGestureEnabled ? _handleVerticalDragEnd : null,
        onVerticalDragCancel:
            dismissGestureEnabled ? _handleVerticalDragCancel : null,
        child: AnimatedContainer(
          duration:
              _isDragging ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform:
              Matrix4.identity()
                ..translate(0.0, _dragOffset)
                ..scale(dragScale, dragScale),
          transformAlignment: Alignment.topCenter,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28 * dragProgress),
          ),
          clipBehavior: Clip.antiAlias,
          child: Scaffold(
'''
    if old_return not in text:
        raise RuntimeError("mobile player return wrapper not found")
    text = text.replace(old_return, new_return, 1)

    old_close = '''            ],
          ),
        ),
      ),
    );
  }

  /// 构建页面指示器（小圆点）
'''
    new_close = '''              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建页面指示器（小圆点）
'''
    if old_close not in text:
        raise RuntimeError("mobile player wrapper closing block not found")
    text = text.replace(old_close, new_close, 1)

    text = text.replace(
        "                              onPageChanged: (index) {\n"
        "                                setState(() {\n"
        "                                  _currentPage = index;\n"
        "                                });\n"
        "                              },\n",
        "                              onPageChanged: (index) {\n"
        "                                setState(() {\n"
        "                                  _currentPage = index;\n"
        "                                  _dragOffset = 0;\n"
        "                                  _isDragging = false;\n"
        "                                  _canDismissFromStart = false;\n"
        "                                });\n"
        "                              },\n",
        1,
    )

    path.write_text(text, encoding="utf-8")


def patch_queue_page() -> None:
    path = Path("lib/features/player/presentation/queue_page.dart")
    text = path.read_text(encoding="utf-8")

    if "package:flutter/services.dart" not in text:
        text = text.replace(
            "import 'package:flutter/material.dart';\n",
            "import 'package:flutter/material.dart';\n"
            "import 'package:flutter/services.dart';\n",
            1,
        )

    text = text.replace(
        "class QueueBottomSheet extends ConsumerWidget {\n"
        "  const QueueBottomSheet({super.key});\n",
        "class QueueBottomSheet extends ConsumerStatefulWidget {\n"
        "  const QueueBottomSheet({super.key});\n",
        1,
    )

    text = text.replace(
        "  @override\n"
        "  Widget build(BuildContext context, WidgetRef ref) {\n",
        "  @override\n"
        "  ConsumerState<QueueBottomSheet> createState() =>\n"
        "      _QueueBottomSheetState();\n"
        "}\n\n"
        "class _QueueBottomSheetState extends ConsumerState<QueueBottomSheet> {\n"
        "  static const double _estimatedItemExtent = 64;\n\n"
        "  int? _lastAutoScrolledIndex;\n"
        "  bool _scrollScheduled = false;\n\n"
        "  @override\n"
        "  Widget build(BuildContext context) {\n",
        1,
    )

    text = text.replace(
        "                           context,\n"
        "                           ref,\n"
        "                           state,\n",
        "                           context,\n"
        "                           state,\n",
        1,
    )

    text = text.replace(
        "    BuildContext context,\n"
        "    WidgetRef ref,\n"
        "    dynamic state,\n",
        "    BuildContext context,\n"
        "    PlayerState state,\n",
        1,
    )

    text = text.replace(
        "    dynamic state,\n"
        "    PlayerNotifier notifier,\n",
        "    PlayerState state,\n"
        "    PlayerNotifier notifier,\n",
        1,
    )

    header_pattern = re.compile(
        r'''          const SizedBox\(width: 8\),\n          // 标题和歌曲数量\n          Row\(\n            mainAxisSize: MainAxisSize.min,\n            children: \[.*?\n          const Spacer\(\),''',
        re.S,
    )
    header_replacement = '''          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '播放队列',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.playlist.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _buildQueueSummary(state),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),'''
    text, count = header_pattern.subn(header_replacement, text, count=1)
    if count != 1:
        raise RuntimeError(f"queue header block not found: {count}")

    text = text.replace(
        "  ) {\n"
        "    return ReorderableListView.builder(\n",
        "  ) {\n"
        "    _scheduleCurrentSongScroll(scrollController, state.currentIndex);\n\n"
        "    return ReorderableListView.builder(\n",
        1,
    )

    text = text.replace(
        "      onReorder: notifier.reorderPlaylist,\n",
        "      onReorder: (oldIndex, newIndex) {\n"
        "        HapticFeedback.mediumImpact();\n"
        "        notifier.reorderPlaylist(oldIndex, newIndex);\n"
        "      },\n",
        1,
    )

    text = text.replace(
        "           onTap: () => notifier.playPlaylist(state.playlist, startIndex: index),\n",
        "           onTap: () {\n"
        "             HapticFeedback.selectionClick();\n"
        "             notifier.playPlaylist(state.playlist, startIndex: index);\n"
        "           },\n",
        1,
    )

    text = text.replace(
        "    notifier.removeFromPlaylist(index);\n",
        "    HapticFeedback.lightImpact();\n"
        "    notifier.removeFromPlaylist(index);\n",
        1,
    )

    insert_marker = "  /// 移除歌曲\n"
    helpers = '''  String _buildQueueSummary(PlayerState state) {
    final totalSeconds = state.playlist.fold<double>(
      0,
      (sum, song) => sum + song.duration,
    );
    final durationLabel =
        totalSeconds > 0 ? Formatters.formatDuration(totalSeconds) : '--:--';
    final modeLabel = switch (state.playMode) {
      PlayMode.order => '顺序播放',
      PlayMode.loop => '列表循环',
      PlayMode.single => '单曲循环',
      PlayMode.random => '随机播放 · 按当前队列展示',
      PlayMode.singlePlay => '播完停止',
    };
    return '$modeLabel · 约 $durationLabel';
  }

  void _scheduleCurrentSongScroll(
    ScrollController scrollController,
    int currentIndex,
  ) {
    if (currentIndex < 0 ||
        _lastAutoScrolledIndex == currentIndex ||
        _scrollScheduled) {
      return;
    }

    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!mounted || !scrollController.hasClients) return;

      _lastAutoScrolledIndex = currentIndex;
      final position = scrollController.position;
      final target =
          currentIndex * _estimatedItemExtent - position.viewportDimension * 0.35;
      final clampedTarget = target.clamp(0.0, position.maxScrollExtent);
      scrollController.animateTo(
        clampedTarget,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

'''
    if helpers.strip() not in text:
        text = text.replace(insert_marker, helpers + insert_marker, 1)

    path.write_text(text, encoding="utf-8")


def main() -> None:
    patch_shell_layout()
    patch_mobile_player()
    patch_queue_page()
    print("Applied mobile second round changes")


if __name__ == "__main__":
    main()
