import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/color_extraction.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../shared/widgets/favorite_button.dart';
import '../../../dlna/presentation/widgets/cast_button.dart';
import '../../domain/player_state.dart';
import '../providers/player_provider.dart';
import '../queue_page.dart';
import '../utils/player_song_actions.dart';
import 'lyrics_view.dart';
import 'play_controls.dart';
import 'popup_controls.dart';
import 'progress_bar.dart';
import 'vinyl_ring.dart';
import 'volume_control.dart';

/// Desktop / Tablet 沉浸式全屏播放器。
class DesktopFullPlayer extends ConsumerStatefulWidget {
  const DesktopFullPlayer({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => const DesktopFullPlayer(),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      ),
    );
  }

  @override
  ConsumerState<DesktopFullPlayer> createState() => _DesktopFullPlayerState();
}

class _DesktopFullPlayerState extends ConsumerState<DesktopFullPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerStateProvider);
    final notifier = ref.read(playerStateProvider.notifier);
    final theme = Theme.of(context);

    ref.listen<PlayerState>(playerStateProvider, (previous, next) {
      if (previous?.hasSong == true && !next.hasSong && context.mounted) {
        Navigator.of(context).pop();
      }
      if (next.isPlaying && !_rotationController.isAnimating) {
        _rotationController.repeat();
      } else if (!next.isPlaying && _rotationController.isAnimating) {
        _rotationController.stop();
      }
    });

    if (state.isPlaying && !_rotationController.isAnimating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && state.isPlaying && !_rotationController.isAnimating) {
          _rotationController.repeat();
        }
      });
    }

    if (!state.hasSong) {
      return const SizedBox.shrink();
    }

    final song = state.currentSong!;
    final coverUrl = song.coverUrl;
    final palette = ref.watch(playerBackgroundPaletteProvider(song)).value;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: _PlayerBackground(coverUrl: coverUrl, palette: palette),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 1040;
                final horizontalPadding = compact ? 20.0 : 34.0;

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    14,
                    horizontalPadding,
                    20,
                  ),
                  child: Column(
                    children: [
                      _buildTopBar(context, notifier, song.title),
                      const SizedBox(height: 14),
                      Expanded(
                        child:
                            compact
                                ? _buildCompactContent(
                                  context,
                                  state,
                                  notifier,
                                  coverUrl,
                                  palette,
                                )
                                : _buildWideContent(
                                  context,
                                  state,
                                  notifier,
                                  coverUrl,
                                  palette,
                                ),
                      ),
                      const SizedBox(height: 16),
                      _ControlDeck(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PlayerProgressBar(
                              position: state.currentTime,
                              duration: state.duration,
                              onSeek: notifier.seek,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildBottomTools(
                                    context,
                                    state,
                                    notifier,
                                    alignEnd: false,
                                  ),
                                ),
                                PlayControls(
                                  isPlaying: state.isPlaying,
                                  hasPrev: state.hasPrev,
                                  hasNext: state.hasNext,
                                  isBuffering: state.isBuffering,
                                  onPlay: notifier.togglePlay,
                                  onPause: notifier.togglePlay,
                                  onPrev: notifier.playPrev,
                                  onNext: notifier.playNext,
                                  size: compact ? 48 : 54,
                                  showGlow: true,
                                ),
                                Expanded(
                                  child: _buildBottomTools(
                                    context,
                                    state,
                                    notifier,
                                    alignEnd: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideContent(
    BuildContext context,
    PlayerState state,
    PlayerNotifier notifier,
    String? coverUrl,
    CoverPalette? palette,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _NowPlayingCard(
            state: state,
            coverUrl: coverUrl,
            palette: palette,
            rotationController: _rotationController,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          flex: 6,
          child: LyricsView(
            currentPosition: state.currentTime,
            onSeek: notifier.seek,
            song: state.currentSong,
            editable: true,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactContent(
    BuildContext context,
    PlayerState state,
    PlayerNotifier notifier,
    String? coverUrl,
    CoverPalette? palette,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 210,
          child: _NowPlayingCard(
            state: state,
            coverUrl: coverUrl,
            palette: palette,
            rotationController: _rotationController,
            horizontal: true,
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: LyricsView(
            currentPosition: state.currentTime,
            onSeek: notifier.seek,
            song: state.currentSong,
            editable: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    PlayerNotifier notifier,
    String title,
  ) {
    final theme = Theme.of(context);

    return _GlassSurface(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              notifier.closeFullPlayer();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            iconSize: 28,
            tooltip: '收起播放器',
          ),
          const SizedBox(width: 4),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.graphic_eq_rounded,
              size: 19,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '正在播放',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded),
            tooltip: '更多操作',
            onSelected: (value) {
              if (value == 'delete') {
                deleteCurrentSongFromPlayer(context, ref);
              }
            },
            itemBuilder: (context) {
              final colorScheme = Theme.of(context).colorScheme;
              return [
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: colorScheme.error,
                    ),
                    title: Text(
                      '删除当前歌曲',
                      style: TextStyle(color: colorScheme.error),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTools(
    BuildContext context,
    PlayerState state,
    PlayerNotifier notifier, {
    required bool alignEnd,
  }) {
    final children =
        alignEnd
            ? <Widget>[
              PopupVolumeControl(
                volume: state.volume,
                onVolumeChanged: notifier.setVolume,
              ),
              PopupSleepTimerControl(
                status: state.sleepTimer,
                isLive: state.currentSong?.isLive ?? false,
                onSetDuration: notifier.setSleepTimerByDuration,
                onSetAfterSongs: notifier.setSleepTimerAfterSongs,
                onCancel: notifier.cancelSleepTimer,
              ),
              IconButton(
                onPressed: () => QueueBottomSheet.show(context),
                icon: const Icon(Icons.queue_music_rounded),
                tooltip: '播放队列',
              ),
            ]
            : <Widget>[
              FavoriteButton(
                songId: state.currentSong!.id,
                songType: state.currentSong!.type,
                size: 24,
              ),
              PopupPlayModeControl(
                playMode: state.playMode,
                onPlayModeChanged: notifier.setPlayMode,
              ),
              const CastButton(iconSize: 24),
            ];

    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: children,
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  final PlayerState state;
  final String? coverUrl;
  final CoverPalette? palette;
  final Animation<double> rotationController;
  final bool horizontal;

  const _NowPlayingCard({
    required this.state,
    required this.coverUrl,
    required this.palette,
    required this.rotationController,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final song = state.currentSong!;

    final info = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          song.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: horizontal ? TextAlign.left : TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          song.artist ?? '未知艺术家',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: horizontal ? TextAlign.left : TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (song.album?.isNotEmpty == true) ...[
          const SizedBox(height: 5),
          Text(
            song.album!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: horizontal ? TextAlign.left : TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ],
      ],
    );

    return _GlassSurface(
      borderRadius: 28,
      padding: EdgeInsets.all(horizontal ? 20 : 26),
      child:
          horizontal
              ? Row(
                children: [
                  _AlbumArtwork(
                    coverUrl: coverUrl,
                    palette: palette,
                    rotationController: rotationController,
                    size: 164,
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: info),
                ],
              )
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: _AlbumArtwork(
                      coverUrl: coverUrl,
                      palette: palette,
                      rotationController: rotationController,
                      size: 300,
                    ),
                  ),
                  const SizedBox(height: 28),
                  info,
                ],
              ),
    );
  }
}

class _AlbumArtwork extends StatelessWidget {
  final String? coverUrl;
  final CoverPalette? palette;
  final Animation<double> rotationController;
  final double size;

  const _AlbumArtwork({
    required this.coverUrl,
    required this.palette,
    required this.rotationController,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glow = palette?.vibrantColor ?? palette?.dominantColor;

    return VinylRing(
      rotationAnimation: rotationController,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: (glow ?? Colors.black).withValues(alpha: 0.34),
              blurRadius: 42,
              spreadRadius: 2,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child:
            coverUrl == null
                ? _ArtworkPlaceholder(size: size)
                : ExcludeSemantics(
                  child: Image.network(
                    UrlHelper.buildCoverUrl(coverUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _ArtworkPlaceholder(size: size),
                  ),
                ),
      ),
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  final double size;

  const _ArtworkPlaceholder({required this.size});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primaryContainer, colorScheme.tertiaryContainer],
        ),
      ),
      child: Icon(
        Icons.graphic_eq_rounded,
        size: size * 0.35,
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.72),
      ),
    );
  }
}

class _ControlDeck extends StatelessWidget {
  final Widget child;

  const _ControlDeck({required this.child});

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      borderRadius: 26,
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 13),
      child: child,
    );
  }
}

class _GlassSurface extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const _GlassSurface({
    required this.child,
    required this.borderRadius,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PlayerBackground extends StatelessWidget {
  final String? coverUrl;
  final CoverPalette? palette;

  const _PlayerBackground({required this.coverUrl, required this.palette});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dominant = palette?.dominantColor ?? colorScheme.primary;
    final dark = palette?.darkMutedColor ?? colorScheme.surface;
    final vibrant = palette?.vibrantColor ?? colorScheme.tertiary;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (coverUrl != null)
          Transform.scale(
            scale: 1.15,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 74, sigmaY: 74),
              child: Image.network(
                UrlHelper.buildCoverUrl(coverUrl!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.72, -0.62),
              radius: 1.35,
              colors: [
                vibrant.withValues(alpha: 0.42),
                dominant.withValues(alpha: 0.24),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                dark.withValues(alpha: 0.6),
                colorScheme.surface.withValues(alpha: 0.82),
                colorScheme.surface.withValues(alpha: 0.94),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
