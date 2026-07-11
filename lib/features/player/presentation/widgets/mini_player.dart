import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/theme_tokens.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../dlna/presentation/providers/dlna_provider.dart';
import '../providers/player_provider.dart';
import '../queue_page.dart';
import 'mobile_player.dart';
import 'play_controls.dart';
import 'progress_bar.dart';

/// 移动端悬浮迷你播放器
class MiniPlayer extends ConsumerStatefulWidget {
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
    final state = ref.watch(playerStateProvider);
    final notifier = ref.read(playerStateProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = SongloftThemeTokens.of(context);

    if (!state.hasSong) {
      return const SizedBox.shrink();
    }

    final song = state.currentSong!;
    final openPlayer =
        widget.onTap ??
        () {
          MobilePlayer.show(context);
        };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _handleHorizontalDragStart,
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      onLongPress: _openQueue,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Material(
          color: colorScheme.surfaceContainerHigh,
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          clipBehavior: Clip.antiAlias,
          child: Semantics(
            label: '展开播放器',
            hint: '左右滑动切歌，长按打开播放队列',
            button: true,
            child: InkWell(
              onTap: openPlayer,
              child: SizedBox(
                height: 76,
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 9, 8, 6),
                        child: Row(
                          children: [
                            _buildCover(context, song.coverUrl),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      if (ref.watch(
                                        dlnaStateProvider.select(
                                          (s) => s.isCasting,
                                        ),
                                      ))
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 5,
                                          ),
                                          child: Icon(
                                            Icons.cast_connected_rounded,
                                            size: 13,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          song.artist ?? '未知艺术家',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color:
                                                    colorScheme
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
                            const SizedBox(width: 6),
                            Material(
                              color: colorScheme.primaryContainer,
                              shape: const CircleBorder(),
                              child: CompactPlayButton(
                                isPlaying: state.isPlaying,
                                isBuffering: state.isBuffering,
                                onPlay: notifier.togglePlay,
                                onPause: notifier.togglePlay,
                                size: 46,
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  state.hasNext ? notifier.playNext : null,
                              tooltip: '下一首',
                              icon: const Icon(Icons.skip_next_rounded),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 3,
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

  Widget _buildCover(BuildContext context, String? coverUrl) {
    final theme = Theme.of(context);

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        color: theme.colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child:
          coverUrl != null && coverUrl.isNotEmpty
              ? ExcludeSemantics(
                child: Image.network(
                  UrlHelper.buildCoverUrl(coverUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildPlaceholder(theme),
                ),
              )
              : _buildPlaceholder(theme),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Icon(
      Icons.graphic_eq_rounded,
      size: 25,
      color: theme.colorScheme.primary,
    );
  }
}
