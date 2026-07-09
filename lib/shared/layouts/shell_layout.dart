import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/responsive.dart';
import '../../features/home/presentation/plugin_tab_page.dart';
import '../../features/library/presentation/providers/favorite_provider.dart';
import '../../features/player/domain/player_state.dart';
import '../../features/player/presentation/providers/player_provider.dart';
import '../../features/player/presentation/widgets/desktop_player.dart';
import '../../features/player/presentation/widgets/mini_player.dart';
import '../../features/player/presentation/widgets/playlist_drawer.dart';
import '../../features/player/presentation/widgets/tv_player.dart';
import '../utils/responsive_snackbar.dart';
import 'active_destinations.dart';
import 'adaptive_scaffold.dart';
import 'redesigned_desktop_shell.dart';

/// ShellRoute 的布局组件
/// 整合响应式导航、播放器和插件页面保活逻辑。
class ShellLayout extends ConsumerStatefulWidget {
  final Widget child;

  const ShellLayout({super.key, required this.child});

  @override
  ConsumerState<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends ConsumerState<ShellLayout> {
  final _visitedPluginTabs = <String>{};

  int _getCurrentIndex(String location, ActiveDestinations activeDest) {
    if (activeDest.routeToIndex.containsKey(location)) {
      return activeDest.routeToIndex[location]!;
    }

    if (location.startsWith('/playlists')) {
      final idx = activeDest.routeToIndex['/playlists'];
      if (idx != null) return idx;
    }

    if (location.startsWith('/plugin-tab/')) {
      final idx = activeDest.routeToIndex[location];
      if (idx != null) return idx;
    }

    if (location.startsWith('/settings')) {
      final idx = activeDest.routeToIndex['/settings'];
      if (idx != null) return idx;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final activeDest = ref.watch(activeDestinationsProvider);
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _getCurrentIndex(location, activeDest);

    ref.watch(favoriteProvider);

    ref.listen<PlayerState>(playerStateProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ResponsiveSnackBar.showError(context, message: next.errorMessage!);
      }
    });

    final showPlaylistDrawer = ref.watch(
      playerStateProvider.select((s) => s.showPlaylistDrawer),
    );

    final isPluginTab = location.startsWith('/plugin-tab/');
    final isSettings = location.startsWith('/settings');
    final currentEntryPath =
        isPluginTab ? location.replaceFirst('/plugin-tab/', '') : null;

    Widget body;
    if (kIsWeb) {
      if (currentEntryPath != null) {
        _visitedPluginTabs.add(currentEntryPath);
      }

      final validPaths = activeDest.indexToRoute
          .where((r) => r.startsWith('/plugin-tab/'))
          .map((r) => r.replaceFirst('/plugin-tab/', ''))
          .toSet();
      _visitedPluginTabs.retainAll(validPaths);

      if (_visitedPluginTabs.isEmpty) {
        body = widget.child;
      } else {
        body = Stack(
          children: [
            Offstage(offstage: isPluginTab, child: widget.child),
            for (final ep in _visitedPluginTabs)
              Offstage(
                offstage: currentEntryPath != ep,
                child: PluginTabPage(
                  key: ValueKey('plugin-keep-$ep'),
                  entryPath: ep,
                  isActive: currentEntryPath == ep,
                ),
              ),
          ],
        );
      }
    } else if (currentEntryPath != null) {
      body = PluginTabPage(
        key: ValueKey('plugin-active-$currentEntryPath'),
        entryPath: currentEntryPath,
        isActive: true,
      );
    } else {
      body = widget.child;
    }

    final bottomPlayer =
        (isPluginTab || isSettings) ? null : _buildBottomPlayer(context);
    final playlistDrawer =
        showPlaylistDrawer ? const PlaylistDrawer() : null;
    final onDestinationSelected = (int index) {
      if (index >= 0 && index < activeDest.indexToRoute.length) {
        context.go(activeDest.indexToRoute[index]);
      }
    };

    final screenType = context.screenType;
    if (screenType == ScreenType.desktop || screenType == ScreenType.tablet) {
      return RedesignedDesktopShell(
        body: body,
        currentIndex: currentIndex,
        destinations: activeDest.destinations,
        onDestinationSelected: onDestinationSelected,
        bottomPlayer: bottomPlayer,
        playlistDrawer: playlistDrawer,
      );
    }

    return AdaptiveScaffold(
      body: body,
      currentIndex: currentIndex,
      destinations: activeDest.destinations,
      onDestinationSelected: onDestinationSelected,
      bottomPlayer: bottomPlayer,
      playlistDrawer: playlistDrawer,
    );
  }

  Widget _buildBottomPlayer(BuildContext context) {
    final screenType = context.screenType;
    switch (screenType) {
      case ScreenType.mobile:
        return const MiniPlayer();
      case ScreenType.tablet:
      case ScreenType.desktop:
        return const DesktopPlayer();
      case ScreenType.auto_:
        return const MiniPlayer();
      case ScreenType.tv:
        if (defaultTargetPlatform == TargetPlatform.android) {
          return const TvMiniPlayer();
        }
        return const DesktopPlayer();
    }
  }
}
