from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: expected one match, found {count}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


def patch_shell_back() -> None:
    path = Path("lib/shared/layouts/shell_layout.dart")
    text = path.read_text(encoding="utf-8")

    replace_once(
        path,
        """    final routerCanPop = GoRouter.of(context).canPop();
    final childHandlesBack = location == '/settings';
""",
        """    final routerCanPop = GoRouter.of(context).canPop();
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final childHandlesBack = location == '/settings';
""",
    )
    text = path.read_text(encoding="utf-8")
    replace_once(
        path,
        """      canPop: !showPlaylistDrawer && (routerCanPop || childHandlesBack),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (showPlaylistDrawer) {
""",
        """      canPop:
          !showPlaylistDrawer &&
          !keyboardVisible &&
          (routerCanPop || childHandlesBack),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (keyboardVisible) {
          FocusManager.instance.primaryFocus?.unfocus();
          return;
        }

        if (showPlaylistDrawer) {
""",
    )


def patch_plugin_back() -> None:
    path = Path("lib/features/home/presentation/plugin_tab_page_native.dart")
    text = path.read_text(encoding="utf-8")
    marker = """  @override
  Widget build(BuildContext context) {
"""
    method = """  Future<bool> _handleBackButton() async {
    if (!widget.isActive) return false;
    final controller = _webViewController;
    if (controller == null) return false;

    try {
      if (await controller.canGoBack()) {
        await controller.goBack();
        return true;
      }
    } catch (_) {
      // WebView 已释放或正在切换页面时，交给外层导航继续处理。
    }
    return false;
  }

"""
    if method.strip() not in text:
        if marker not in text:
            raise RuntimeError("Plugin build marker not found")
        text = text.replace(marker, method + marker, 1)

    old = """    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          if (_errorMessage != null)
            _buildErrorView(colorScheme)
          else
            _buildWebView(theme),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
"""
    new = """    return BackButtonListener(
      onBackButtonPressed: _handleBackButton,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            if (_errorMessage != null)
              _buildErrorView(colorScheme)
            else
              _buildWebView(theme),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
"""
    if old not in text and "return BackButtonListener(" not in text:
        raise RuntimeError("Plugin SafeArea block not found")
    if old in text:
        text = text.replace(old, new, 1)
    path.write_text(text, encoding="utf-8")


def patch_mini_player() -> None:
    path = Path("lib/features/player/presentation/widgets/mini_player.dart")
    text = path.read_text(encoding="utf-8")
    text = text.replace(
        "import 'package:flutter/material.dart';\n",
        "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';\n",
        1,
    )
    text = text.replace(
        "import '../providers/player_provider.dart';\n",
        "import '../providers/player_provider.dart';\nimport '../queue_page.dart';\n",
        1,
    )

    old_header = """class MiniPlayer extends ConsumerWidget {
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
"""
    new_header = """class MiniPlayer extends ConsumerStatefulWidget {
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  double _horizontalDragDistance = 0;

  void _handleHorizontalDragStart(DragStartDetails details) {
    _horizontalDragDistance = 0;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _horizontalDragDistance += details.delta.dx;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final distance = _horizontalDragDistance;
    _horizontalDragDistance = 0;

    if (distance.abs() < 42 && velocity.abs() < 520) return;

    final direction = velocity.abs() >= 520 ? velocity : distance;
    final state = ref.read(playerStateProvider);
    final notifier = ref.read(playerStateProvider.notifier);

    if (direction < 0 && state.hasNext) {
      HapticFeedback.selectionClick();
      notifier.playNext();
    } else if (direction > 0 && state.hasPrev) {
      HapticFeedback.selectionClick();
      notifier.playPrev();
    }
  }

  void _openQueue() {
    HapticFeedback.selectionClick();
    QueueBottomSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
"""
    if old_header not in text:
        raise RuntimeError("MiniPlayer class header not found")
    text = text.replace(old_header, new_header, 1)
    text = text.replace("        onTap ??\n", "        widget.onTap ??\n", 1)
    text = text.replace(
        """    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
""",
        """    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _handleHorizontalDragStart,
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      onLongPress: _openQueue,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
""",
        1,
    )
    text = text.replace(
        """          label: '展开播放器',
          button: true,
""",
        """          label: '展开播放器',
          hint: '左右滑动切歌，长按打开播放队列',
          button: true,
""",
        1,
    )
    old_end = """      ),
    );
  }

  Widget _buildCover(BuildContext context, String? coverUrl) {
"""
    new_end = """        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context, String? coverUrl) {
"""
    if old_end not in text:
        raise RuntimeError("MiniPlayer return end not found")
    text = text.replace(old_end, new_end, 1)
    path.write_text(text, encoding="utf-8")


def patch_mobile_player() -> None:
    path = Path("lib/features/player/presentation/widgets/mobile_player.dart")
    text = path.read_text(encoding="utf-8")
    text = text.replace(
        "import 'package:flutter/material.dart';\n",
        "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';\n",
        1,
    )

    text = text.replace(
        """    if (shouldClose) {
      _closePlayer();
      return;
    }
    setState(() {
      _isDragging = false;
      _dragOffset = 0;
    });
  }
""",
        """    if (shouldClose) {
      HapticFeedback.mediumImpact();
      _closePlayer();
      return;
    }
    _resetDismissDrag();
  }

  void _resetDismissDrag() {
    if (!mounted) return;
    setState(() {
      _isDragging = false;
      _dragOffset = 0;
    });
  }

  Widget _buildDismissGesture({required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: _handleVerticalDragStart,
      onVerticalDragUpdate:
          (details) => _handleVerticalDragUpdate(
            details,
            MediaQuery.sizeOf(context).height * 0.45,
          ),
      onVerticalDragEnd: _handleVerticalDragEnd,
      onVerticalDragCancel: _resetDismissDrag,
      child: child,
    );
  }
""",
        1,
    )

    old_root = """    return GestureDetector(
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
"""
    new_root = """    final dragProgress = (_dragOffset / (size.height * 0.45)).clamp(
      0.0,
      1.0,
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(playerStateProvider.notifier).closeFullPlayer();
        }
      },
      child: ColoredBox(
        color: Colors.black,
        child: AnimatedContainer(
          duration:
              _isDragging ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _dragOffset, 0),
          transformAlignment: Alignment.topCenter,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28 * dragProgress),
          ),
          clipBehavior: Clip.antiAlias,
          child: Scaffold(
"""
    if old_root not in text:
        raise RuntimeError("MobilePlayer root gesture block not found")
    text = text.replace(old_root, new_root, 1)

    text = text.replace(
        """                    _buildTopBar(context, notifier, state),
""",
        """                    _buildDismissGesture(
                      child: _buildTopBar(context, notifier, state),
                    ),
""",
        1,
    )
    old_cover = """                                Center(
                                  child: VinylRing(
                                    rotationAnimation: _rotationController,
                                    child: _buildCover(
                                      context,
                                      coverUrl,
                                      size.width * 0.75,
                                      palette: palette,
                                    ),
                                  ),
                                ),
"""
    new_cover = """                                Center(
                                  child: _buildDismissGesture(
                                    child: VinylRing(
                                      rotationAnimation: _rotationController,
                                      child: _buildCover(
                                        context,
                                        coverUrl,
                                        size.width * 0.75,
                                        palette: palette,
                                      ),
                                    ),
                                  ),
                                ),
"""
    if old_cover not in text:
        raise RuntimeError("MobilePlayer cover block not found")
    text = text.replace(old_cover, new_cover, 1)

    old_end = """          ),
        ),
      ),
    );
  }

  /// 构建页面指示器（小圆点）
"""
    new_end = """            ),
          ),
        ),
      ),
    );
  }

  /// 构建页面指示器（小圆点）
"""
    if old_end not in text:
        raise RuntimeError("MobilePlayer root closing block not found")
    text = text.replace(old_end, new_end, 1)
    path.write_text(text, encoding="utf-8")


def patch_queue_sheet() -> None:
    path = Path("lib/features/player/presentation/queue_page.dart")
    text = path.read_text(encoding="utf-8")

    old_header = """class QueueBottomSheet extends ConsumerWidget {
  const QueueBottomSheet({super.key});

  /// 显示播放队列底部弹窗
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QueueBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
"""
    new_header = """class QueueBottomSheet extends ConsumerStatefulWidget {
  const QueueBottomSheet({super.key});

  /// 显示播放队列底部弹窗
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QueueBottomSheet(),
    );
  }

  @override
  ConsumerState<QueueBottomSheet> createState() => _QueueBottomSheetState();
}

class _QueueBottomSheetState extends ConsumerState<QueueBottomSheet> {
  ScrollController? _activeScrollController;
  int? _lastCenteredIndex;

  void _scheduleCurrentSong(int currentIndex) {
    final controller = _activeScrollController;
    if (controller == null || currentIndex < 0) return;
    if (_lastCenteredIndex == currentIndex) return;
    _lastCenteredIndex = currentIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      const estimatedItemExtent = 72.0;
      final viewport = controller.position.viewportDimension;
      final target = (currentIndex * estimatedItemExtent - viewport * 0.34)
          .clamp(0.0, controller.position.maxScrollExtent);
      controller.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _formatQueueDuration(List<Song> songs) {
    final totalSeconds = songs.fold<double>(
      0,
      (total, song) => total + (song.isLive ? 0 : song.duration),
    );
    if (totalSeconds <= 0) return '时长未知';
    final duration = Duration(seconds: totalSeconds.round());
    if (duration.inHours > 0) {
      final minutes = duration.inMinutes.remainder(60);
      return '约 ${duration.inHours} 小时 ${minutes} 分钟';
    }
    return '约 ${duration.inMinutes.clamp(1, 9999)} 分钟';
  }

  String _queueSummary(PlayerState state) {
    final mode = state.playMode == PlayMode.random ? ' · 随机模式' : '';
    return '${state.playlist.length} 首 · ${_formatQueueDuration(state.playlist)}$mode';
  }

  @override
  Widget build(BuildContext context) {
"""
    if old_header not in text:
        raise RuntimeError("QueueBottomSheet class header not found")
    text = text.replace(old_header, new_header, 1)

    old_listen = """    ref.listen<PlayerState>(playerStateProvider, (previous, next) {
      if (previous != null &&
          previous.playlist.isNotEmpty &&
          next.playlist.isEmpty) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }
    });
"""
    new_listen = """    ref.listen<PlayerState>(playerStateProvider, (previous, next) {
      if (previous != null &&
          previous.playlist.isNotEmpty &&
          next.playlist.isEmpty) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
      if (previous?.currentIndex != next.currentIndex) {
        _scheduleCurrentSong(next.currentIndex);
      }
    });
"""
    if old_listen not in text:
        raise RuntimeError("Queue listener not found")
    text = text.replace(old_listen, new_listen, 1)

    text = text.replace(
        """      builder: (context, scrollController) {
        return Container(
""",
        """      builder: (context, scrollController) {
        _activeScrollController = scrollController;
        _scheduleCurrentSong(state.currentIndex);
        return Container(
""",
        1,
    )

    old_header_body = """          const SizedBox(width: 8),
          // 标题和歌曲数量
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '播放队列',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          const Spacer(),
"""
    new_header_body = """          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                  _queueSummary(state),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
"""
    if old_header_body not in text:
        raise RuntimeError("Queue header content not found")
    text = text.replace(old_header_body, new_header_body, 1)
    text = text.replace(
        """    dynamic state,
    PlayerNotifier notifier,
""",
        """    PlayerState state,
    PlayerNotifier notifier,
""",
        1,
    )

    old_remove = """  void _removeSong(
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
"""
    new_remove = """  void _removeSong(
    BuildContext context,
    PlayerNotifier notifier,
    int index,
    Song song,
  ) {
    final removingCurrent = ref.read(playerStateProvider).currentIndex == index;
    notifier.removeFromPlaylist(index);

    if (removingCurrent) {
      ResponsiveSnackBar.show(
        context,
        message: '已移除当前歌曲「${song.title}」',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('已移除「${song.title}」'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () => notifier.insertToPlaylist(index, song),
          ),
        ),
      );
  }
"""
    if old_remove not in text:
        raise RuntimeError("Queue remove method not found")
    text = text.replace(old_remove, new_remove, 1)
    path.write_text(text, encoding="utf-8")


def main() -> None:
    patch_shell_back()
    patch_plugin_back()
    patch_mini_player()
    patch_mobile_player()
    patch_queue_sheet()
    print("Applied mobile polish round 2")


if __name__ == "__main__":
    main()
