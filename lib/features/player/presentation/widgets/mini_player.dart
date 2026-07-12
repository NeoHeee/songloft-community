import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/accessibility.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/theme_tokens.dart';
import '../../../../shared/widgets/cover_image.dart';
import '../../../dlna/presentation/providers/dlna_provider.dart';
import '../providers/player_provider.dart';
import '../queue_page.dart';
import 'mobile_player_gesture_host.dart';
import 'play_controls.dart';
import 'progress_bar.dart';

enum MiniPlayerDensity { regular, compact }

/// 移动端悬浮迷你播放器。
///
/// 普通页面使用 regular；设置页和插件页使用 compact，减少对内容区的占用。
class MiniPlayer extends ConsumerStatefulWidget {
  final VoidCallback? onTap;
  final MiniPlayerDensity density;

  const MiniPlayer({
    super.key,
    this.onTap,
    this.density = MiniPlayerDensity.regular,
  });

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  double _horizontalDragDistance = 0;
  bool _retryRequested = false;

  bool get _isCompact => widget.density == MiniPlayerDensity.compact;

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

  Future<void> _retryPlayback() async {
    if (_retryRequested) return;
    setState(() => _retryRequested = true);
    final notifier = ref.read(playerStateProvider.notifier);
    notifier.clearError();
    try {
      await notifier.togglePlay();
    } finally {
      if (mounted) setState(() => _retryRequested = false);
    }
  }

  void _openQueue() {
    HapticFeedback.selectionClick();
    QueueBottomSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerStateProvider);
    final notifier = ref.read(playerStateProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = SongloftThemeTokens.of(context);
    final textScaleFactor = AppAccessibility.textScaleOf(context);
    final textScaleDelta = textScaleFactor - 1.0;
    final hasPlaybackError = state.errorMessage?.isNotEmpty == true;

    if (!state.hasSong) {
      return const SizedBox.shrink();
    }

    final song = state.currentSong!;
    final openPlayer =
        widget.onTap ??
        () {
          MobilePlayerGestureHost.show(context);
        };
    final height =
        (_isCompact ? 58.0 : 76.0) +
        textScaleDelta * (_isCompact ? 18.0 : 24.0);
    final coverSize = _isCompact ? 38.0 : 54.0;
    final playButtonSize = 48.0 + textScaleDelta * 4;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _handleHorizontalDragStart,
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      onLongPress: _openQueue,
      child: Padding(
        padding: _isCompact
            ? const EdgeInsets.fromLTRB(6, 3, 6, 4)
            : const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Material(
          color: _isCompact
              ? colorScheme.surfaceContainer
              : colorScheme.surfaceContainerHigh,
          elevation: _isCompact ? 3 : 10,
          shadowColor: Colors.black.withValues(alpha: _isCompact ? 0.12 : 0.22),
          borderRadius: BorderRadius.circular(
            _isCompact ? tokens.controlRadius : tokens.cardRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Semantics(
            label: hasPlaybackError
                ? '当前歌曲播放失败'
                : (_isCompact ? '展开薄版播放器' : '展开播放器'),
            hint: hasPlaybackError ? '点击重试按钮重新播放，左右滑动可切歌' : '左右滑动切歌，长按打开播放队列',
            button: true,
            child: InkWell(
              onTap: openPlayer,
              child: SizedBox(
                height: height,
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: _isCompact
                            ? const EdgeInsets.fromLTRB(7, 5, 6, 3)
                            : const EdgeInsets.fromLTRB(10, 9, 8, 6),
                        child: Row(
                          children: [
                            _buildCover(song.coverUrl, coverSize),
                            SizedBox(width: _isCompact ? 9 : 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    style:
                                        (_isCompact
                                                ? theme.textTheme.bodySmall
                                                : theme.textTheme.bodyMedium)
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.1,
                                            ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: _isCompact ? 1 : 3),
                                  Row(
                                    children: [
                                      if (ref.watch(
                                        dlnaStateProvider.select(
                                          (s) => s.isCasting,
                                        ),
                                      ))
                                        Padding(
                                          padding: EdgeInsets.only(
                                            right: _isCompact ? 4 : 5,
                                          ),
                                          child: Icon(
                                            Icons.cast_connected_rounded,
                                            size: _isCompact ? 11 : 13,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          hasPlaybackError
                                              ? state.errorMessage!
                                              : (song.artist ?? '未知艺术家'),
                                          style:
                                              (_isCompact
                                                      ? theme
                                                            .textTheme
                                                            .labelSmall
                                                      : theme
                                                            .textTheme
                                                            .bodySmall)
                                                  ?.copyWith(
                                                    color: hasPlaybackError
                                                        ? colorScheme.error
                                                        : colorScheme
                                                              .onSurfaceVariant,
                                                  ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: _isCompact ? 4 : 6),
                            Material(
                              color: hasPlaybackError
                                  ? colorScheme.errorContainer
                                  : colorScheme.primaryContainer,
                              shape: const CircleBorder(),
                              child: hasPlaybackError
                                  ? SizedBox(
                                      width: playButtonSize,
                                      height: playButtonSize,
                                      child: IconButton(
                                        onPressed:
                                            _retryRequested || state.isRetrying
                                            ? null
                                            : _retryPlayback,
                                        tooltip: '重试播放',
                                        icon:
                                            _retryRequested || state.isRetrying
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                    ),
                                              )
                                            : const Icon(Icons.refresh_rounded),
                                      ),
                                    )
                                  : CompactPlayButton(
                                      isPlaying: state.isPlaying,
                                      isBuffering: state.isBuffering,
                                      onPlay: notifier.togglePlay,
                                      onPause: notifier.togglePlay,
                                      size: playButtonSize,
                                    ),
                            ),
                            if (!_isCompact)
                              IconButton(
                                onPressed: state.hasNext
                                    ? notifier.playNext
                                    : null,
                                tooltip: '下一首',
                                icon: const Icon(Icons.skip_next_rounded),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: _isCompact ? 2 : 3,
                      child: PlayerProgressBar(
                        position: state.currentTime,
                        duration: state.duration,
                        onSeek: notifier.seek,
                        mini: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover(String? coverUrl, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_isCompact ? 10 : AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isCompact ? 0.1 : 0.16),
            blurRadius: _isCompact ? 6 : 10,
            offset: Offset(0, _isCompact ? 2 : 4),
          ),
        ],
      ),
      child: CoverImage(
        coverUrl: coverUrl,
        size: size,
        borderRadius: _isCompact ? 10 : AppRadius.md,
        placeholderIcon: Icons.graphic_eq_rounded,
      ),
    );
  }
}
