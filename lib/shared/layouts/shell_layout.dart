import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'server_connection_host.dart';

/// StatefulShellRoute 的布局组件。
/// 整合响应式导航、播放器、独立标签导航栈和插件页面保活逻辑。
class ShellLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ShellLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends ConsumerState<ShellLayout> {
  static const _exitConfirmationWindow = Duration(seconds: 2);
  static const _homeBranch = 0;
  static const _libraryBranch = 1;
  static const _playlistsBranch = 2;
  static const _pluginsBranch = 3;
  static const _settingsBranch = 4;

  final _visitedPluginTabs = <String>{};
  DateTime? _lastBackPressedAt;

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

  int _branchForRoute(String route) {
    if (route == '/') return _homeBranch;
    if (route == '/library') return _libraryBranch;
    if (route.startsWith('/playlists')) return _playlistsBranch;
    if (route.startsWith('/plugin-tab/')) return _pluginsBranch;
    if (route.startsWith('/settings')) return _settingsBranch;
    return _homeBranch;
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

    // 动态插件标签共用一个 StatefulShellBranch，但每个访问过的插件页面
    // 都保留自己的 Widget/WebView 状态。配置中被移除的插件会立即释放。
    if (currentEntryPath != null && currentEntryPath != '_empty') {
      _visitedPluginTabs.add(currentEntryPath);
    }

    final validPluginPaths =
        activeDest.indexToRoute
            .where((route) => route.startsWith('/plugin-tab/'))
            .map((route) => route.replaceFirst('/plugin-tab/', ''))
            .toSet();
    _visitedPluginTabs.retainAll(validPluginPaths);

    final Widget body;
    if (_visitedPluginTabs.isEmpty) {
      body = widget.navigationShell;
    } else {
      body = Stack(
        children: [
          TickerMode(
            enabled: !isPluginTab,
            child: Offstage(
              offstage: isPluginTab,
              child: widget.navigationShell,
            ),
          ),
          for (final entryPath in _visitedPluginTabs)
            TickerMode(
              enabled: currentEntryPath == entryPath,
              child: Offstage(
                offstage: currentEntryPath != entryPath,
                child: PluginTabPage(
                  key: ValueKey('plugin-keep-$entryPath'),
                  entryPath: entryPath,
                  isActive: currentEntryPath == entryPath,
                ),
              ),
            ),
        ],
      );
    }

    final shellBody = ServerConnectionHost(child: body);
    final bottomPlayer = _buildBottomPlayer(
      context,
      compact: isPluginTab || isSettings,
    );
    final playlistDrawer = showPlaylistDrawer ? const PlaylistDrawer() : null;

    void onDestinationSelected(int index) {
      if (index < 0 || index >= activeDest.indexToRoute.length) return;

      _lastBackPressedAt = null;
      final route = activeDest.indexToRoute[index];
      final targetBranch = _branchForRoute(route);

      if (targetBranch == _pluginsBranch) {
        if (location != route) context.go(route);
        return;
      }

      // 再次点击当前栏目时回到该栏目的根页面；切换到其他栏目时恢复
      // 其上次保留的页面栈和滚动现场。
      widget.navigationShell.goBranch(
        targetBranch,
        initialLocation: widget.navigationShell.currentIndex == targetBranch,
      );
    }

    final screenType = context.screenType;
    if (screenType == ScreenType.desktop || screenType == ScreenType.tablet) {
      return RedesignedDesktopShell(
        body: shellBody,
        currentIndex: currentIndex,
        destinations: activeDest.destinations,
        onDestinationSelected: onDestinationSelected,
        bottomPlayer: bottomPlayer,
        playlistDrawer: playlistDrawer,
      );
    }

    if (screenType != ScreenType.mobile) {
      return AdaptiveScaffold(
        body: shellBody,
        currentIndex: currentIndex,
        destinations: activeDest.destinations,
        onDestinationSelected: onDestinationSelected,
        bottomPlayer: bottomPlayer,
        playlistDrawer: playlistDrawer,
      );
    }

    final routerCanPop = GoRouter.of(context).canPop();
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final childHandlesBack = location == '/settings';
    if (location != '/') {
      _lastBackPressedAt = null;
    }

    return PopScope(
      canPop:
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
          ref.read(playerStateProvider.notifier).closePlaylistDrawer();
          return;
        }

        if (childHandlesBack) {
          // 移动端设置页有自己的两级返回逻辑：详情 -> 设置列表 -> 首页。
          return;
        }

        _handleMobileRootBack(context, location);
      },
      child: AdaptiveScaffold(
        body: shellBody,
        currentIndex: currentIndex,
        destinations: activeDest.destinations,
        onDestinationSelected: onDestinationSelected,
        bottomPlayer: bottomPlayer,
        playlistDrawer: playlistDrawer,
      ),
    );
  }

  void _handleMobileRootBack(BuildContext context, String location) {
    if (location != '/') {
      _lastBackPressedAt = null;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      widget.navigationShell.goBranch(_homeBranch);
      return;
    }

    final now = DateTime.now();
    final shouldExit =
        _lastBackPressedAt != null &&
        now.difference(_lastBackPressedAt!) <= _exitConfirmationWindow;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (shouldExit) {
      _lastBackPressedAt = null;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        SystemNavigator.pop();
      }
      return;
    }

    _lastBackPressedAt = now;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('再按一次退出应用'),
        duration: _exitConfirmationWindow,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildBottomPlayer(BuildContext context, {required bool compact}) {
    final screenType = context.screenType;

    if (compact && screenType != ScreenType.tv) {
      return const MiniPlayer(density: MiniPlayerDensity.compact);
    }

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
