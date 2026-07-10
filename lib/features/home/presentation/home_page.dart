import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/responsive.dart';
import '../../../core/utils/url_helper.dart';
import '../../../features/jsplugin/presentation/widgets/jsplugin_grid.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../player/presentation/providers/player_provider.dart';
import '../../playlist/domain/playlist.dart';
import '../../playlist/presentation/providers/playlist_provider.dart';
import 'widgets/playlist_carousel.dart';
import 'widgets/section_header.dart';
import 'widgets/stats_strip.dart';

/// 新版首页仪表盘
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistListProvider(null));
    final normalAsync = ref.watch(playlistListProvider('normal'));
    final radioAsync = ref.watch(playlistListProvider('radio'));
    final normalCount = normalAsync.value?.totalCount ?? 0;
    final radioCount = radioAsync.value?.totalCount ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(playlistListProvider(null));
          ref.invalidate(playlistListProvider('normal'));
          ref.invalidate(playlistListProvider('radio'));
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _DashboardHeader(
                normalCount: normalCount,
                radioCount: radioCount,
              ),
            ),
            SliverToBoxAdapter(
              child: playlistsAsync.when(
                data: (state) => _DashboardContent(
                  playlists: state.items,
                  normalCount: normalCount,
                  radioCount: radioCount,
                ),
                loading: () => const _LoadingContent(),
                error: (error, stack) => _ErrorContent(
                  error: error.toString(),
                  onRetry: () => ref.invalidate(playlistListProvider(null)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final List<Playlist> playlists;
  final int normalCount;
  final int radioCount;

  const _DashboardContent({
    required this.playlists,
    required this.normalCount,
    required this.radioCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPlaylistId = ref.watch(sourcePlaylistIdProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final normal = playlists.where((p) => p.type == 'normal').toList();
    final radios = playlists.where((p) => p.type == 'radio').toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1380),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _pagePadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const _QuickActions(),
              const SizedBox(height: 30),
              if (playlists.isEmpty)
                EmptyState(
                  icon: Icons.library_music_outlined,
                  title: '你的音乐空间还是空的',
                  subtitle: '创建第一个歌单，或者前往歌曲库开始整理音乐',
                  action: FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.playlists),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('创建歌单'),
                  ),
                )
              else ...[
                if (normal.isNotEmpty) ...[
                  _PlaylistSection(
                    title: '为你准备的歌单',
                    playlists: normal,
                    currentPlaylistId: currentPlaylistId,
                    isPlaying: isPlaying,
                    onViewAll: () => context.go(AppRoutes.playlists),
                  ),
                  const SizedBox(height: 34),
                ],
                if (radios.isNotEmpty) ...[
                  _PlaylistSection(
                    title: '私人电台',
                    icon: Icons.radio_rounded,
                    playlists: radios,
                    currentPlaylistId: currentPlaylistId,
                    isPlaying: isPlaying,
                  ),
                  const SizedBox(height: 34),
                ],
              ],
              const JSPluginGrid(),
              const SizedBox(height: 28),
              StatsStrip(normalCount: normalCount, radioCount: radioCount),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 120),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final int normalCount;
  final int radioCount;

  const _DashboardHeader({required this.normalCount, required this.radioCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWide = context.isWideScreen;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1380),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            _pagePadding(context),
            context.responsive<double>(mobile: 18, tablet: 24, desktop: 28),
            _pagePadding(context),
            0,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isWide ? 34 : 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.tertiary,
                  Color.lerp(colorScheme.tertiary, Colors.black, 0.18)!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.24),
                  blurRadius: 34,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -35,
                  top: -55,
                  child: _GlowCircle(size: isWide ? 230 : 155),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 7),
                          Text(
                            '你的私人音乐空间',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _greeting(),
                          maxLines: 1,
                          softWrap: false,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.1,
                            fontSize: isWide ? 42 : 31,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '选一张歌单，让熟悉的旋律接管现在。',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 600;
                        final metrics = <Widget>[
                          _Metric(
                            icon: Icons.queue_music_rounded,
                            value: '$normalCount',
                            label: '歌单',
                            compact: compact,
                          ),
                          _Metric(
                            icon: Icons.radio_rounded,
                            value: '$radioCount',
                            label: '电台',
                            compact: compact,
                          ),
                          _Metric(
                            icon: Icons.cloud_done_rounded,
                            value: '在线',
                            label: '音乐库',
                            compact: compact,
                          ),
                        ];

                        if (!compact) {
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: metrics,
                          );
                        }

                        return Row(
                          children: [
                            for (var i = 0; i < metrics.length; i++) ...[
                              Expanded(child: metrics[i]),
                              if (i != metrics.length - 1)
                                const SizedBox(width: 8),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了，放点轻松的';
    if (hour < 12) return '早上好，今天听什么？';
    if (hour < 14) return '中午好，给自己一点节奏';
    if (hour < 18) return '下午好，继续播放喜欢的';
    return '晚上好，音乐时间到了';
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;

  const _GlowCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.1),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool compact;

  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 16 : 17, color: Colors.white),
            SizedBox(width: compact ? 5 : 8),
            Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 14 : null,
              ),
            ),
            SizedBox(width: compact ? 3 : 5),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
                fontSize: compact ? 14 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        icon: Icons.library_music_rounded,
        title: '浏览歌曲库',
        subtitle: '查找全部歌曲',
        onTap: () => context.go(AppRoutes.library),
      ),
      _ActionData(
        icon: Icons.queue_music_rounded,
        title: '管理歌单',
        subtitle: '整理你的收藏',
        onTap: () => context.go(AppRoutes.playlists),
      ),
      _ActionData(
        icon: Icons.extension_rounded,
        title: '发现插件',
        subtitle: '扩展更多能力',
        onTap: () => context.push(AppRoutes.pluginRegistry),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        if (compact) {
          return Column(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                _ActionCard(data: actions[i]),
                if (i != actions.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              Expanded(child: _ActionCard(data: actions[i])),
              if (i != actions.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _ActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _ActionCard extends StatelessWidget {
  final _ActionData data;

  const _ActionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.26),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(data.icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 19,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Playlist> playlists;
  final int? currentPlaylistId;
  final bool isPlaying;
  final VoidCallback? onViewAll;

  const _PlaylistSection({
    required this.title,
    this.icon,
    required this.playlists,
    required this.currentPlaylistId,
    required this.isPlaying,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          icon: icon,
          actionText: onViewAll == null ? null : '查看全部',
          onAction: onViewAll,
        ),
        const SizedBox(height: AppSpacing.md),
        if (context.isWideScreen)
          _PlaylistGrid(
            playlists: playlists,
            currentPlaylistId: currentPlaylistId,
            isPlaying: isPlaying,
          )
        else
          PlaylistCarousel(
            playlists: playlists,
            currentPlaylistId: currentPlaylistId,
            isPlaying: isPlaying,
            onPlaylistTap: (playlist) {
              context.push('/playlists/${playlist.id}');
            },
          ),
      ],
    );
  }
}

class _PlaylistGrid extends StatelessWidget {
  final List<Playlist> playlists;
  final int? currentPlaylistId;
  final bool isPlaying;

  const _PlaylistGrid({
    required this.playlists,
    required this.currentPlaylistId,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final columns = context.responsive<int>(mobile: 2, tablet: 3, desktop: 4);
    final itemCount = playlists.length > columns * 2
        ? columns * 2
        : playlists.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final current = playlist.id == currentPlaylistId;
        return _PlaylistCard(
          playlist: playlist,
          isCurrent: current,
          isPlaying: current && isPlaying,
        );
      },
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final bool isCurrent;
  final bool isPlaying;

  const _PlaylistCard({
    required this.playlist,
    required this.isCurrent,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/playlists/${playlist.id}'),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: colorScheme.surfaceContainerHighest,
                      border: isCurrent
                          ? Border.all(color: colorScheme.primary, width: 2)
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (playlist.coverImageUrl != null)
                          CachedNetworkImage(
                            imageUrl: UrlHelper.buildCoverUrl(
                              playlist.coverImageUrl!,
                            ),
                            fit: BoxFit.cover,
                            placeholder: (_, _) =>
                                _CoverPlaceholder(colorScheme: colorScheme),
                            errorWidget: (_, _, _) =>
                                _CoverPlaceholder(colorScheme: colorScheme),
                          )
                        else
                          _CoverPlaceholder(colorScheme: colorScheme),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? colorScheme.primary
                                  : Colors.black.withValues(alpha: 0.62),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.equalizer_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 11),
              Text(
                playlist.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? colorScheme.primary : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                '${playlist.songCount} 首歌曲',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final ColorScheme colorScheme;

  const _CoverPlaceholder({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primaryContainer, colorScheme.tertiaryContainer],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.graphic_eq_rounded,
          size: 50,
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(height: 86, borderRadius: BorderRadius.circular(22)),
          const SizedBox(height: 28),
          SkeletonLoader(height: 22, width: 160, borderRadius: AppRadius.smAll),
          const SizedBox(height: 16),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (_, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader.card(size: 150),
                  const SizedBox(height: 10),
                  SkeletonLoader(
                    height: 13,
                    width: 110,
                    borderRadius: AppRadius.smAll,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorContent({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('首页加载失败', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              error,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重新加载'),
            ),
          ],
        ),
      ),
    );
  }
}

double _pagePadding(BuildContext context) {
  return context.responsive<double>(
    mobile: AppSpacing.md,
    tablet: AppSpacing.lg,
    desktop: 28,
  );
}
