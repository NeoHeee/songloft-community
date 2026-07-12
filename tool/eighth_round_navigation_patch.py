from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding='utf-8')
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{path}: expected one match, found {count}\n{old[:160]}')
    file.write_text(text.replace(old, new, 1), encoding='utf-8')


def replace_all(path: str, old: str, new: str, expected: int) -> None:
    file = Path(path)
    text = file.read_text(encoding='utf-8')
    count = text.count(old)
    if count != expected:
        raise RuntimeError(f'{path}: expected {expected} matches, found {count}')
    file.write_text(text.replace(old, new), encoding='utf-8')


# Shell: never let root Navigator decide by accident; use route policy as fallback.
replace_once(
    'lib/shared/layouts/shell_layout.dart',
    "import '../../core/theme/responsive.dart';",
    "import '../../core/navigation/mobile_back_policy.dart';\nimport '../../core/theme/responsive.dart';",
)
replace_once(
    'lib/shared/layouts/shell_layout.dart',
    "  static const _exitConfirmationWindow = Duration(seconds: 2);\n",
    '',
)
replace_once(
    'lib/shared/layouts/shell_layout.dart',
    "  DateTime? _lastBackPressedAt;",
    "  final MobileExitTracker _exitTracker = MobileExitTracker();",
)
replace_all(
    'lib/shared/layouts/shell_layout.dart',
    "      _lastBackPressedAt = null;",
    "      _exitTracker.reset();",
    1,
)
replace_once(
    'lib/shared/layouts/shell_layout.dart',
    """    final routerCanPop = GoRouter.of(context).canPop();
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
""",
    """    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (!MobileBackPolicy.isHome(location)) {
      _exitTracker.reset();
    }

    return PopScope(
      canPop: false,
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

        final parentRoute = MobileBackPolicy.parentRouteFor(location);
        if (parentRoute != null) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(parentRoute);
          }
          return;
        }

        _handleMobileRootBack(context, location);
      },
""",
)
replace_once(
    'lib/shared/layouts/shell_layout.dart',
    """  void _handleMobileRootBack(BuildContext context, String location) {
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
""",
    """  void _handleMobileRootBack(BuildContext context, String location) {
    if (!MobileBackPolicy.isHome(location)) {
      _exitTracker.reset();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      widget.navigationShell.goBranch(_homeBranch);
      return;
    }

    final now = DateTime.now();
    final shouldExit = _exitTracker.shouldExit(now);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (shouldExit) {
      _exitTracker.reset();
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        SystemNavigator.pop();
      }
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: const Text('再按一次退出应用'),
        duration: _exitTracker.confirmationWindow,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
""",
)

# Songs library: system back closes the keyboard or exits selection before route navigation.
replace_once(
    'lib/features/library/presentation/mobile_library_page.dart',
    """  @override
  Widget build(BuildContext context) {
    final state = ref.watch(songsListProvider);
    final currentSong = ref.watch(currentSongProvider);

    return Scaffold(
""",
    """  Future<bool> _handleBackButton() async {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
      return true;
    }

    final state = ref.read(songsListProvider);
    if (state.isSelectionMode) {
      ref.read(songsListProvider.notifier).exitSelectionMode();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(songsListProvider);
    final currentSong = ref.watch(currentSongProvider);

    return BackButtonListener(
      onBackButtonPressed: _handleBackButton,
      child: Scaffold(
""",
)
replace_once(
    'lib/features/library/presentation/mobile_library_page.dart',
    """      ),
    );
  }

  Widget _buildAppBar(SongsListState state) {
""",
    """      ),
      ),
    );
  }

  Widget _buildAppBar(SongsListState state) {
""",
)

# Playlist root: transient modes consume back; normal state falls through to Shell -> home.
replace_once(
    'lib/features/playlist/presentation/playlists_page.dart',
    """  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(playlistListProvider(_selectedType));

    return Scaffold(
""",
    """  Future<bool> _handleBackButton() async {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
      return true;
    }
    if (_isSortMode) {
      _cancelSortMode();
      return true;
    }
    if (_isSelectionMode) {
      _toggleSelectMode();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(playlistListProvider(_selectedType));

    return BackButtonListener(
      onBackButtonPressed: _handleBackButton,
      child: Scaffold(
""",
)
replace_once(
    'lib/features/playlist/presentation/playlists_page.dart',
    """              ),
    );
  }

  Future<void> _refreshPlaylists() async {
""",
    """              ),
      ),
    );
  }

  Future<void> _refreshPlaylists() async {
""",
)

# Playlist detail: left button and system back share the same transient-state handling.
replace_all(
    'lib/features/playlist/presentation/playlist_detail_page.dart',
    'onPressed: _goBack,',
    'onPressed: _handleBack,',
    2,
)
replace_once(
    'lib/features/playlist/presentation/playlist_detail_page.dart',
    """    return playlistAsync.when(
""",
    """    return BackButtonListener(
      onBackButtonPressed: _handleBackButton,
      child: playlistAsync.when(
""",
)
replace_once(
    'lib/features/playlist/presentation/playlist_detail_page.dart',
    """    );
  }

  void _goBack() {
""",
    """      ),
    );
  }

  Future<bool> _handleBackButton() async {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
      return true;
    }
    if (_isSortMode) {
      _cancelSortMode();
      return true;
    }
    if (_isSelectMode) {
      _exitSelectMode();
      return true;
    }
    return false;
  }

  Future<void> _handleBack() async {
    if (await _handleBackButton()) return;
    _goBack();
  }

  void _goBack() {
""",
)

# Settings: remove nested PopScope competition and only consume transient mobile detail/keyboard.
replace_once(
    'lib/features/settings/presentation/settings_page.dart',
    """  @override
  Widget build(BuildContext context) {
    final isMobile = !context.isWideScreen || context.isTv;

    if (isMobile && _mobileDetailIndex != null) {
      final category = _categories[_mobileDetailIndex!];
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            setState(() => _mobileDetailIndex = null);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () => setState(() => _mobileDetailIndex = null),
            ),
            title: Text(category.title),
          ),
          body: _buildCategoryContent(_mobileDetailIndex!),
        ),
      );
    }
""",
    """  Future<bool> _handleBackButton() async {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
      return true;
    }
    if (_mobileDetailIndex != null) {
      setState(() => _mobileDetailIndex = null);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !context.isWideScreen || context.isTv;

    if (isMobile && _mobileDetailIndex != null) {
      final category = _categories[_mobileDetailIndex!];
      return BackButtonListener(
        onBackButtonPressed: _handleBackButton,
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () => setState(() => _mobileDetailIndex = null),
            ),
            title: Text(category.title),
          ),
          body: _buildCategoryContent(_mobileDetailIndex!),
        ),
      );
    }
""",
)
replace_once(
    'lib/features/settings/presentation/settings_page.dart',
    """    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go(AppRoutes.home);
        }
      },
      child: settingsScaffold,
    );
""",
    """    return BackButtonListener(
      onBackButtonPressed: _handleBackButton,
      child: settingsScaffold,
    );
""",
)

# Login: a single back no longer exits the Android app immediately.
replace_once(
    'lib/features/auth/presentation/login_page.dart',
    "import 'package:flutter/foundation.dart' show kIsWeb;",
    "import 'package:flutter/foundation.dart'\n    show defaultTargetPlatform, kIsWeb, TargetPlatform;",
)
replace_once(
    'lib/features/auth/presentation/login_page.dart',
    "import '../../../core/network/base_url_provider.dart';",
    "import '../../../core/navigation/mobile_back_policy.dart';\nimport '../../../core/network/base_url_provider.dart';",
)
replace_once(
    'lib/features/auth/presentation/login_page.dart',
    "  final _apiUrlController = TextEditingController();\n",
    "  final _apiUrlController = TextEditingController();\n  final MobileExitTracker _exitTracker = MobileExitTracker();\n",
)
replace_once(
    'lib/features/auth/presentation/login_page.dart',
    """    return _buildDefaultLayout(context, authState, theme, colorScheme);
  }

  // ========== 默认布局（手机/平板/桌面）==========
""",
    """    return BackButtonListener(
      onBackButtonPressed: _handleMobileBackButton,
      child: _buildDefaultLayout(context, authState, theme, colorScheme),
    );
  }

  Future<bool> _handleMobileBackButton() async {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
      return true;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (_exitTracker.shouldExit(DateTime.now())) {
      _exitTracker.reset();
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        SystemNavigator.pop();
      }
      return true;
    }

    messenger.showSnackBar(
      SnackBar(
        content: const Text('再按一次退出应用'),
        duration: _exitTracker.confirmationWindow,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return true;
  }

  // ========== 默认布局（手机/平板/桌面）==========
""",
)

# Full-screen plugin page: web history first, then app route, with home fallback for deep links.
replace_once(
    'lib/features/home/presentation/plugin_webview_page_native.dart',
    "import 'package:flutter_riverpod/flutter_riverpod.dart';",
    "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:go_router/go_router.dart';",
)
replace_once(
    'lib/features/home/presentation/plugin_webview_page_native.dart',
    "import '../../../core/storage/secure_storage.dart';",
    "import '../../../core/router/app_router.dart';\nimport '../../../core/storage/secure_storage.dart';",
)
replace_once(
    'lib/features/home/presentation/plugin_webview_page_native.dart',
    """  void _sendThemeToPlugin(String theme) {
    _webViewController?.evaluateJavascript(
      source: "window.postMessage({type:'songloft-theme',theme:'$theme'},'*')",
    );
  }

  @override
""",
    """  void _sendThemeToPlugin(String theme) {
    _webViewController?.evaluateJavascript(
      source: "window.postMessage({type:'songloft-theme',theme:'$theme'},'*')",
    );
  }

  void _closeOrHome() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
""",
)
replace_all(
    'lib/features/home/presentation/plugin_webview_page_native.dart',
    'Navigator.of(context).pop();',
    '_closeOrHome();',
    3,
)

# CI: run navigation tests and allow the eighth-round stacked PR as a base.
replace_once(
    '.github/workflows/ui-redesign-check.yml',
    "      - mobile-sixth-round\n",
    "      - mobile-sixth-round\n      - mobile-seventh-round\n",
)
replace_once(
    '.github/workflows/ui-redesign-check.yml',
    """      - name: Run network recovery tests
        run: flutter test test/core/network
""",
    """      - name: Run network recovery tests
        run: flutter test test/core/network
      - name: Run mobile navigation tests
        run: flutter test test/core/navigation
""",
)

print('Eighth-round mobile navigation patch applied successfully.')
