import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/song.dart';
import '../lyric_adjust_page.dart';
import '../providers/lyric_provider.dart';

/// 沉浸式歌词显示组件。
///
/// 自动跟随当前播放位置，用户手动滚动时暂停跟随，点击任意歌词可跳转。
class LyricsView extends ConsumerStatefulWidget {
  final Duration currentPosition;
  final ValueChanged<Duration>? onSeek;
  final Song? song;
  final bool editable;

  const LyricsView({
    super.key,
    required this.currentPosition,
    this.onSeek,
    this.song,
    this.editable = false,
  });

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  final ScrollController _scrollController = ScrollController();

  bool _isUserScrolling = false;
  Timer? _resumeTimer;
  int _lastScrolledIndex = -1;

  static const double _lineHeight = 64;
  static const Duration _resumeDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLine(int index) {
    if (!_scrollController.hasClients) return;

    final targetOffset = index * _lineHeight;
    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _onScroll() {
    if (_scrollController.position.isScrollingNotifier.value) {
      _onUserScrollStart();
    }
  }

  void _onUserScrollStart() {
    _isUserScrolling = true;
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_resumeDelay, _onResumeAutoScroll);
  }

  void _onResumeAutoScroll() {
    _isUserScrolling = false;
    final lyricState = ref.read(lyricStateProvider);
    if (lyricState.currentIndex >= 0) {
      _scrollToLine(lyricState.currentIndex);
    }
  }

  bool get _shouldShowEditButton {
    if (!widget.editable) return false;
    final song = widget.song;
    if (song == null || song.type != 'local') return false;
    final lyricState = ref.read(lyricStateProvider);
    return lyricState.hasLyrics &&
        !lyricState.isLoading &&
        !lyricState.loadFailed;
  }

  Future<void> _openAdjustPage() async {
    final song = widget.song;
    final lyricState = ref.read(lyricStateProvider);
    final lyricText = lyricState.rawLyricText;
    if (song == null || lyricText == null || lyricText.isEmpty) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LyricAdjustPage(
          song: song,
          originalLyric: lyricText,
        ),
      ),
    );

    if (saved == true && mounted) {
      ref.read(lyricStateProvider.notifier).invalidate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lyricState = ref.watch(lyricStateProvider);

    Widget content;
    if (lyricState.isLoading) {
      content = const _LyricsStatus(
        icon: Icons.hourglass_top_rounded,
        title: '正在加载歌词',
        subtitle: '稍等一下，音乐马上有字幕',
        loading: true,
      );
    } else if (lyricState.loadFailed) {
      content = const _LyricsStatus(
        icon: Icons.cloud_off_rounded,
        title: '歌词加载失败',
        subtitle: '可以稍后重试，播放不会受到影响',
      );
    } else if (!lyricState.hasLyrics) {
      content = const _LyricsStatus(
        icon: Icons.lyrics_outlined,
        title: '暂无歌词',
        subtitle: '先听旋律，也是一种浪漫',
      );
    } else {
      final currentIndex = lyricState.currentIndex;
      if (currentIndex != _lastScrolledIndex &&
          !_isUserScrolling &&
          currentIndex >= 0) {
        _lastScrolledIndex = currentIndex;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isUserScrolling) {
            _scrollToLine(currentIndex);
          }
        });
      }

      content = LayoutBuilder(
        builder: (context, constraints) {
          final verticalPadding = ((constraints.maxHeight - _lineHeight) / 2)
              .clamp(0.0, double.infinity);

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _onUserScrollStart();
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                vertical: verticalPadding,
                horizontal: 22,
              ),
              itemCount: lyricState.lyrics.length,
              itemBuilder: (context, index) {
                final lyric = lyricState.lyrics[index];
                final isCurrent = index == currentIndex;

                return Semantics(
                  button: true,
                  selected: isCurrent,
                  label: '跳转到此歌词位置',
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () {
                        widget.onSeek?.call(lyric.time);
                        _isUserScrolling = false;
                        _resumeTimer?.cancel();
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        height: _lineHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? colorScheme.primaryContainer.withValues(
                                  alpha: 0.68,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          border: isCurrent
                              ? Border.all(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.22,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: isCurrent ? 4 : 0,
                              height: isCurrent ? 28 : 0,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            if (isCurrent) const SizedBox(width: 13),
                            Expanded(
                              child: Text(
                                lyric.text.isEmpty ? '…' : lyric.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: isCurrent
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurface.withValues(
                                          alpha: 0.46,
                                        ),
                                  fontSize: isCurrent ? 19 : 15,
                                  fontWeight: isCurrent
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: content),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 72,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.surface.withValues(alpha: 0.72),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lyrics_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '歌词',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_shouldShowEditButton)
            Positioned(
              top: 10,
              right: 10,
              child: IconButton.filledTonal(
                icon: const Icon(Icons.tune_rounded, size: 20),
                tooltip: '调整歌词',
                onPressed: _openAdjustPage,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 54,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      colorScheme.surface.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LyricsStatus extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;

  const _LyricsStatus({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: loading
                ? SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colorScheme.primary,
                    ),
                  )
                : Icon(icon, size: 32, color: colorScheme.primary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
