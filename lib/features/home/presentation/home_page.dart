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
    final normalPlaylistsAsync = ref.watch(playlistListProvider('normal'));
    final radioPlaylistsAsync = ref.watch(playlistListProvider('radio'));

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
                normalCount: normalPlaylistsAsync.value?.totalCount ?? 0,
                radioCount: radioPlaylistsAsync.value?.totalCount ?? 0,
              ),
            ),
            SliverToBoxAdapter(
              child: playlistsAsync.when(
                data: (state) => _buildContent(
                  context,
                  ref,
                  state.items,
                  normalTotalCount:
                      normalPlaylistsAsync.value?.totalCount ?? 0,
                  radioTotalCount:
                      radioPlaylistsAsync.value?.totalCount ?? 0,
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

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Playlist> playlists, {
    required int normalTotalCount,
    required int radioTotalCount,
  }) {
    final currentPlaylistId = ref.watch(sourcePlaylistIdProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final normalPlaylists = playlists.where((p) => p.type == 'normal').toList();
    final radioPlaylists = playlists.where((p) => p.type == 'radio').toList();
    final isWide = context.isWideScreen;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1380),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive<double>(
              mobile: AppSpacing.md,
              tablet: AppSpacing.lg,
              desktop: 28,
            ),
          ),
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
                if (normalPlaylists.isNotEmpty) ...[
                  SectionHeader(
                    title: '为你准备的歌单',
                    actionText: '查看全部',
                    onAction: () => context.go(AppRoutes.playlists),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (isWide)
                    _PlaylistGrid(
                      playlists: normalPlaylists,
                      currentPlaylistId: currentPlaylistId,
                      isPlaying: isPlaying,
                    )
                  else
                    PlaylistCarousel(
                      playlists: normalPlaylists,
                      currentPlaylistId: currentPlaylistId,
                      isPlaying: isPlaying,
                      onPlaylistTap: (playlist) {
                        context.push('/playlists/${playlist.id}');
                      },
                    ),
                  const SizedBox(height: 34),
                ],
                if (radioPlaylists.isNotEmpty) ...[
                  const SectionHeader(
                    title: '私人电台',
                    icon: Icons.radio_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (isWide)
                    _PlaylistGrid(
                      playlists: radioPlaylists,
                      currentPlaylistId: currentPlaylistId,
                      isPlaying: isPlaying,
                    )
                  else
                    PlaylistCarousel(
                      playlists: radioPlaylists,
                      currentPlaylistId: currentPlaylistId,
                      isPlaying: isPlaying,
                      onPlaylistTap: (playlist) {
                        context.push('/playlists/${playlist.id}');
                      },
                    ),
                  const SizedBox(height: 34),
                ],
              ],
              const JSPluginGrid(),
              const SizedBox(height: 28),
              StatsStrip(
                normalCount: normalTotalCount,
                radioCount: radioTotalCount,
              ),
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

  const _DashboardHeader({
    required this.normalCount,
    required this.radioCount,
  });

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
            context.responsive<double>(
              mobile: AppSpacing.md,
              tablet: AppSpacing.lg,
              desktop: 28,
            ),
            context.responsive<double>(mobile: 18, tablet: 24, desktop: 28),
            context.responsive<double>(
              mobile: AppSpacing.md,
              tablet: AppSpacing.lg,
              desktop: 28,
            ),
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
                  right: -34,
                  top: -46,
                  child: _GlowCircle(
                    size: isWide ? 220 : 150,
                    opacity: 0.12,
                  ),
                ),
                Positioned(
                  right: isWide ? 130 : 10,
                  bottom: -70,
                  child: _GlowCircle(
                    size: isWide ? 180 : 120,
                    opacity: 0.09,
                  ),
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
                    Text(
                      _getGreeting(),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.1,
                        fontSize: isWide ? 42 : 31,
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
                    const SizedBox(height: 26),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _HeroMetric(
                          icon: Icons.queue_music_rounded,
                          value: '$normalCount',
                          label: '歌单',
                        ),
                        _HeroMetric(
                          icon: Icons.radio_rounded,
                          value: '$radioCount',
                          label: '电台',
                        ),
                        const _HeroMetric(
                          icon: Icons.cloud_done_rounded,
                          value: '在线',
                          label: '音乐库',
                        ),
                      ],
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

  String _getGreeting() {
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
  final double opacity;

  const _GlowCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeroMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final actions = [
          _QuickActionData(
            icon: Icons.library_music_rounded,
            title: '浏览歌曲库',
            subtitle: '查找全部歌曲',
            onTap: () => context.go(AppRoutes.library),
          ),
          _QuickActionData(
            icon: Icons.queue_music_rounded,
            title: '管理歌单',
            subtitle: '整理你的收藏',
            onTap: () => context.go(AppRoutes.playlists),
          ),
          _QuickActionData(
            icon: Icons.extension_rounded,
            title: '发现插件',
            subtitle: '扩展更多能力',
            onTap: () => context.push(AppRoutes.pluginRegistry),
          ),
        ];

        if (compact) {
          return Column(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                _QuickActionCard(data: actions[i]),
                if (i != actions.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              Expanded(child: _QuickActionCard(data: actions[i])),
              if (i != actions.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionCard({required this.data});

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
                        fontWeight: FontWeight.w750,
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

class _PlaylistGrid extends StatelessWidget {
  final List<Playlist> playlists;
  final int? currentPlaylistId;
  final bool isPlaying;

  const _PlaylistGrid({
    required this.playlists,
    this.currentPlaylistId,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = context.responsive<int>(
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: playlists.length > crossAxisCount * 2
          ? crossAxisCount * 2
          : playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final isCurrent = playlist.id == currentPlaylistId;
        return _GridPlaylistCard(
          playlist: playlist,
          isCurrent: isCurrent,
          isPlaying: isPlaying && isCurrent,
          onTap: () => context.push('/playlists/${playlist.id}'),
        );
      },
    );
  }
}

class _GridPlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;

  const _GridPlaylistCard({
    required this.playlist,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: '打开歌单 ${playlist.name}',
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          playlist.coverImageUrl != null
                              ? _buildNetworkImage(
                                  playlist.coverImageUrl!,
                                  colorScheme,
                                )
                              : _buildPlaceholder(colorScheme),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: AnimatedOpacity(
                              opacity: isCurrent ? 1 : 0.88,
                              duration: const Duration(milliseconds: 180),
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
                    fontWeight: FontWeight.w750,
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
      ),
    );
  }

  Widget _buildNetworkImage(String coverUrl, ColorScheme colorScheme) {
    return CachedNetworkImage(
      imageUrl: UrlHelper.buildCoverUrl(coverUrl),
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildPlaceholder(colorScheme),
      errorWidget: (context, url, error) => _buildPlaceholder(colorScheme),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.tertiaryContainer,
          ],
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
          SkeletonLoader(
            height: 86,
            borderRadius: BorderRadius.circular(22),
          ),
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
