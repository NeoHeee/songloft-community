import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../shared/widgets/favorite_button.dart';
import '../../../dlna/presentation/widgets/cast_button.dart';
import '../../domain/player_state.dart';
import '../providers/player_provider.dart';
import 'desktop_full_player.dart';
import 'equalizer_panel.dart';
import 'play_controls.dart';
import 'popup_controls.dart';
import 'progress_bar.dart';
import 'volume_control.dart';

/// 桌面端悬浮播放坞
class DesktopPlayer extends ConsumerWidget {
  const DesktopPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerStateProvider);
    final notifier = ref.read(playerStateProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        elevation: 14,
        shadowColor: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 96,
          child: Column(
            children: [
              SizedBox(
                height: 4,
                child: ClickableProgressBar(
                  position: state.currentTime,
                  duration: state.duration,
                  onSeek: notifier.seek,
                  height: 4,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _buildSongInfo(context, state)),
                      Expanded(
                        flex: 4,
                        child: _buildPlayControls(context, state, notifier),
                      ),
                      Expanded(
                        flex: 3,
                        child: _buildToolbar(context, state, notifier),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(BuildContext context, PlayerState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!state.hasSong) {
      return Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            ),
            child: Icon(Icons.graphic_eq_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Text(
            '准备播放音乐',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final song = state.currentSong!;
    final coverUrl = song.coverUrl;

    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: '打开全屏播放器',
            child: GestureDetector(
              onTap: () => DesktopFullPlayer.show(context),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      color: colorScheme.surfaceContainerHighest,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child:
                        coverUrl != null
                            ? ExcludeSemantics(
                              child: Image.network(
                                UrlHelper.buildCoverUrl(coverUrl),
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, _, _) => Icon(
                                      Icons.graphic_eq_rounded,
                                      color: colorScheme.primary,
                                    ),
                              ),
                            )
                            : Icon(
                              Icons.graphic_eq_rounded,
                              color: colorScheme.primary,
                            ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist ?? '未知艺术家',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
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
        const SizedBox(width: 8),
        FavoriteButton(songId: song.id, songType: song.type, size: 20),
      ],
    );
  }

  Widget _buildPlayControls(
    BuildContext context,
    PlayerState state,
    PlayerNotifier notifier,
  ) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PlayControls(
          isPlaying: state.isPlaying,
          hasPrev: state.hasPrev,
          hasNext: state.hasNext,
          isBuffering: state.isBuffering,
          onPlay: notifier.togglePlay,
          onPause: notifier.togglePlay,
          onPrev: notifier.playPrev,
          onNext: notifier.playNext,
          size: 42,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              Formatters.formatDuration(state.currentTime.inSeconds.toDouble()),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '  ·  ',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              Formatters.formatDuration(state.duration.inSeconds.toDouble()),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    PlayerState state,
    PlayerNotifier notifier,
  ) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPlayModeButton(state, notifier),
        Flexible(
          child: ResponsiveVolumeControl(
            volume: state.volume,
            onVolumeChanged: notifier.setVolume,
          ),
        ),
        IconButton(
          onPressed: () => showEqualizerSheet(context),
          icon: const Icon(Icons.equalizer_rounded, size: 20),
          tooltip: '均衡器',
          visualDensity: VisualDensity.compact,
        ),
        const CastButton(iconSize: 20, visualDensity: VisualDensity.compact),
        _buildSleepTimerButton(state, notifier),
        _buildLyricsButton(context, state, theme),
        IconButton(
          onPressed: notifier.togglePlaylistDrawer,
          icon: Icon(
            Icons.queue_music_rounded,
            size: 20,
            color: state.showPlaylistDrawer ? theme.colorScheme.primary : null,
          ),
          tooltip: '播放列表',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildPlayModeButton(PlayerState state, PlayerNotifier notifier) {
    return PopupPlayModeControl(
      playMode: state.playMode,
      onPlayModeChanged: notifier.setPlayMode,
    );
  }

  Widget _buildSleepTimerButton(PlayerState state, PlayerNotifier notifier) {
    return PopupSleepTimerControl(
      status: state.sleepTimer,
      isLive: state.currentSong?.isLive ?? false,
      onSetDuration: notifier.setSleepTimerByDuration,
      onSetAfterSongs: notifier.setSleepTimerAfterSongs,
      onCancel: notifier.cancelSleepTimer,
    );
  }

  Widget _buildLyricsButton(
    BuildContext context,
    PlayerState state,
    ThemeData theme,
  ) {
    final hasSong = state.hasSong;
    final hasLyrics = hasSong && state.currentSong?.lyricUrl != null;

    return IconButton(
      onPressed: hasSong ? () => DesktopFullPlayer.show(context) : null,
      icon: Icon(
        Icons.lyrics_rounded,
        size: 20,
        color:
            hasLyrics
                ? null
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      tooltip: '歌词',
      visualDensity: VisualDensity.compact,
    );
  }
}
