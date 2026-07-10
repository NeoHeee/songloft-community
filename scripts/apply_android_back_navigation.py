from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: expected one match, found {count}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


def patch_shell_layout() -> None:
    path = Path("lib/shared/layouts/shell_layout.dart")
    text = path.read_text(encoding="utf-8")

    if "package:flutter/services.dart" not in text:
        text = text.replace(
            "import 'package:flutter/material.dart';\n",
            "import 'package:flutter/material.dart';\n"
            "import 'package:flutter/services.dart';\n",
            1,
        )

    if "_exitConfirmationWindow" not in text:
        text = text.replace(
            "class _ShellLayoutState extends ConsumerState<ShellLayout> {\n"
            "  final _visitedPluginTabs = <String>{};\n",
            "class _ShellLayoutState extends ConsumerState<ShellLayout> {\n"
            "  static const _exitConfirmationWindow = Duration(seconds: 2);\n\n"
            "  final _visitedPluginTabs = <String>{};\n"
            "  DateTime? _lastBackPressedAt;\n",
            1,
        )

    old_destination = """    void onDestinationSelected(int index) {
      if (index >= 0 && index < activeDest.indexToRoute.length) {
        context.go(activeDest.indexToRoute[index]);
      }
    }
"""
    new_destination = """    void onDestinationSelected(int index) {
      if (index >= 0 && index < activeDest.indexToRoute.length) {
        _lastBackPressedAt = null;
        context.go(activeDest.indexToRoute[index]);
      }
    }
"""
    if old_destination in text:
        text = text.replace(old_destination, new_destination, 1)

    old_mobile_return = """    return AdaptiveScaffold(
      body: body,
      currentIndex: currentIndex,
      destinations: activeDest.destinations,
      onDestinationSelected: onDestinationSelected,
      bottomPlayer: bottomPlayer,
      playlistDrawer: playlistDrawer,
    );
  }

  Widget _buildBottomPlayer(BuildContext context) {
"""
    new_mobile_return = """    final routerCanPop = GoRouter.of(context).canPop();
    final childHandlesBack = location == '/settings';
    if (location != '/') {
      _lastBackPressedAt = null;
    }

    return PopScope(
      canPop:
          !showPlaylistDrawer &&
          (routerCanPop || childHandlesBack),
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
      ),
    );
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
"""

    if old_mobile_return not in text and "_handleMobileRootBack" not in text:
        raise RuntimeError("ShellLayout mobile return block not found")
    if old_mobile_return in text:
        text = text.replace(old_mobile_return, new_mobile_return, 1)

    path.write_text(text, encoding="utf-8")


def patch_settings_page() -> None:
    path = Path("lib/features/settings/presentation/settings_page.dart")
    text = path.read_text(encoding="utf-8")

    old_root = """    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SettingsMasterDetail(
        categories: _categories,
        selectedIndex: _selectedCategory,
        onCategorySelected: (i) {
          setState(() {
            _selectedCategory = i;
            if (isMobile) {
              _mobileDetailIndex = i;
            }
          });
        },
        contentBuilder: (_, index) => _buildCategoryContent(index),
        header: _buildServerInfoCard(),
      ),
    );
"""
    new_root = """    final settingsScaffold = Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SettingsMasterDetail(
        categories: _categories,
        selectedIndex: _selectedCategory,
        onCategorySelected: (i) {
          setState(() {
            _selectedCategory = i;
            if (isMobile) {
              _mobileDetailIndex = i;
            }
          });
        },
        contentBuilder: (_, index) => _buildCategoryContent(index),
        header: _buildServerInfoCard(),
      ),
    );

    if (!isMobile) {
      return settingsScaffold;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go(AppRoutes.home);
        }
      },
      child: settingsScaffold,
    );
"""

    if old_root not in text and "final settingsScaffold = Scaffold(" not in text:
        raise RuntimeError("Settings root scaffold block not found")
    if old_root in text:
        text = text.replace(old_root, new_root, 1)

    path.write_text(text, encoding="utf-8")


def main() -> None:
    patch_shell_layout()
    patch_settings_page()
    print("Applied Android back navigation changes")


if __name__ == "__main__":
    main()
