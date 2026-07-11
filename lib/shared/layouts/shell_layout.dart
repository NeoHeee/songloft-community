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

/// ShellRoute 的布局组件
/// 整合响应式导航、播放器和插件页面保活逻辑。
class ShellLayout extends ConsumerStatefulWidget {
  final Widget child;

  const ShellLayout({super.key, required this.child});

  @override
  ConsumerState<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends ConsumerState<ShellLayout> {
  static const _exitConfirmationWindow = Duration(seconds: 2);

  final _visitedPluginTabs = <String>{};
  DateTime? _lastBackPressedAt;
  bool _tvExitDialogOpen = false;

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

      final validPaths =
          activeDest.indexToRoute
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
    final playlistDrawer = showPlaylistDrawer ? const PlaylistDrawer() : null;

    void onDestinationSelected(int index) {
      if (index >= 0 && index < activeDest.indexToRoute.length) {
        _lastBackPressedAt = null;
        context.go(activeDest.indexToRoute[index]);
      }
    }

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

    if (screenType != ScreenType.mobile) {
      return AdaptiveScaffold(
        body: body,
        currentIndex: currentIndex,
        destinations: activeDest.destinations,
        onDestinationSelected: onDestinationSelected,
        bottomPlayer: bottomPlayer,
        playlistDrawer: playlistDrawer,
        onClosePlaylistDrawer:
            ref.read(playerStateProvider.notifier).closePlaylistDrawer,
        onExitRequested: () => _showTvExitDialog(context),
      );
    }

    final routerCanPop = GoRouter.of(context).canPop();
    final childHandlesBack = location == '/settings';
    if (location != '/') {
      _lastBackPressedAt = null;
    }

    return PopScope(
      canPop: !showPlaylistDrawer && (routerCanPop || childHandlesBack),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

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
        body: body,
        currentIndex: currentIndex,
        destinations: activeDest.destinations,
        onDestinationSelected: onDestinationSelected,
        bottomPlayer: bottomPlayer,
        playlistDrawer: playlistDrawer,
        onClosePlaylistDrawer:
            ref.read(playerStateProvider.notifier).closePlaylistDrawer,
      ),
    );
  }

  Future<void> _showTvExitDialog(BuildContext context) async {
    if (_tvExitDialogOpen) return;
    _tvExitDialogOpen = true;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(
            Icons.power_settings_new_rounded,
            color: colorScheme.primary,
            size: 40,
          ),
          title: const Text('退出 Songloft？', textAlign: TextAlign.center),
          content: const Text(
            '退出后当前音乐将停止播放，并返回电视系统桌面。播放队列会保留。',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.power_settings_new_rounded),
              label: const Text('退出应用'),
            ),
          ],
        );
      },
    );

    _tvExitDialogOpen = false;
    if (confirmed != true || !mounted) return;

    await ref.read(playerStateProvider.notifier).stopForAppExit();
    if (!mounted) return;
    await SystemNavigator.pop();
  }

  void _handleMobileRootBack(BuildContext context, String location) {
    if (location != '/') {
      _lastBackPressedAt = null;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      context.go('/');
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
