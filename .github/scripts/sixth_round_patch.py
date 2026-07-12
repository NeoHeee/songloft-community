from pathlib import Path


def replace(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text()
    if old not in text:
        if new in text:
            return
        raise SystemExit(f'{path}: pattern not found: {old[:80]!r}')
    file.write_text(text.replace(old, new, 1))


# Shared system accessibility helpers.
Path('lib/core/theme/accessibility.dart').write_text(
    """import 'package:flutter/material.dart';

/// Centralized access to system accessibility preferences used by Songloft.
class AppAccessibility {
  AppAccessibility._();

  static double textScaleOf(BuildContext context) {
    return MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 2.0).toDouble();
  }

  static bool reduceMotionOf(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  static Duration motionDuration(BuildContext context, Duration duration) {
    return reduceMotionOf(context) ? Duration.zero : duration;
  }
}
"""
)

# App root: read the real system preferences and feed them into the theme.
replace(
    'lib/main.dart',
    "import 'core/theme/app_theme.dart';\n",
    "import 'core/theme/accessibility.dart';\nimport 'core/theme/app_theme.dart';\n",
)
main_path = Path('lib/main.dart')
main_text = main_path.read_text()
if 'final textScaleFactor = AppAccessibility.textScaleOf(context);' not in main_text:
    start = main_text.index('      builder: (context, child) {')
    end = main_text.index('      },\n    );', start)
    builder = """      builder: (context, child) {
        // 在 builder 中获取系统字号和减少动画偏好，同时应用响应式主题。
        final mediaQuery = MediaQuery.of(context);
        final screenType = _getScreenType(mediaQuery.size.width);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textScaleFactor = AppAccessibility.textScaleOf(context);
        final reduceMotion = AppAccessibility.reduceMotionOf(context);
        final responsiveTheme =
            isDark
                ? AppTheme.darkTheme(
                  screenType: screenType,
                  themePack: themePack,
                  textScaleFactor: textScaleFactor,
                  reduceMotion: reduceMotion,
                )
                : AppTheme.lightTheme(
                  screenType: screenType,
                  themePack: themePack,
                  textScaleFactor: textScaleFactor,
                  reduceMotion: reduceMotion,
                );
        return Theme(data: responsiveTheme, child: child!);
      },
"""
    main_path.write_text(main_text[:start] + builder + main_text[end + len('      },\n') :])

# Theme geometry and no-transition page routing.
replace(
    'lib/core/theme/app_theme.dart',
    """  static ThemeData lightTheme({
    ScreenType screenType = ScreenType.mobile,
    SongloftThemePack? themePack,
  }) {
""",
    """  static ThemeData lightTheme({
    ScreenType screenType = ScreenType.mobile,
    SongloftThemePack? themePack,
    double textScaleFactor = 1.0,
    bool reduceMotion = false,
  }) {
""",
)
replace(
    'lib/core/theme/app_theme.dart',
    """      themePack ?? SongloftThemePacks.classic,
    );
  }

  /// 暗色主题
""",
    """      themePack ?? SongloftThemePacks.classic,
      textScaleFactor,
      reduceMotion,
    );
  }

  /// 暗色主题
""",
)
replace(
    'lib/core/theme/app_theme.dart',
    """  static ThemeData darkTheme({
    ScreenType screenType = ScreenType.mobile,
    SongloftThemePack? themePack,
  }) {
""",
    """  static ThemeData darkTheme({
    ScreenType screenType = ScreenType.mobile,
    SongloftThemePack? themePack,
    double textScaleFactor = 1.0,
    bool reduceMotion = false,
  }) {
""",
)
replace(
    'lib/core/theme/app_theme.dart',
    """      themePack ?? SongloftThemePacks.classic,
    );
  }

  static ThemeData _buildTheme(
""",
    """      themePack ?? SongloftThemePacks.classic,
      textScaleFactor,
      reduceMotion,
    );
  }

  static ThemeData _buildTheme(
""",
)
replace(
    'lib/core/theme/app_theme.dart',
    """    Brightness brightness,
    ScreenType screenType,
    SongloftThemePack themePack,
  ) {
""",
    """    Brightness brightness,
    ScreenType screenType,
    SongloftThemePack themePack,
    double textScaleFactor,
    bool reduceMotion,
  ) {
""",
)
replace(
    'lib/core/theme/app_theme.dart',
    """    final isDesktopOrTv =
        screenType == ScreenType.desktop || screenType == ScreenType.tv;
    final palette = themePack.paletteFor(brightness);
""",
    """    final isDesktopOrTv =
        screenType == ScreenType.desktop || screenType == ScreenType.tv;
    final normalizedTextScale = textScaleFactor.clamp(1.0, 2.0).toDouble();
    final textScaleDelta = normalizedTextScale - 1.0;
    final buttonHeight =
        isTv
            ? 56.0 + textScaleDelta * 8
            : isDesktopOrTv
            ? 44.0 + textScaleDelta * 6
            : 48.0 + textScaleDelta * 8;
    final iconButtonExtent =
        isTv
            ? 56.0 + textScaleDelta * 8
            : isDesktopOrTv
            ? 44.0 + textScaleDelta * 6
            : 48.0 + textScaleDelta * 8;
    final navigationBarHeight = 72.0 + textScaleDelta * 24;
    final toolbarHeight =
        (isTv ? 72.0 : 56.0) + textScaleDelta * (isTv ? 16 : 12);
    final palette = themePack.paletteFor(brightness);
""",
)
replace(
    'lib/core/theme/app_theme.dart',
    """      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashFactory: InkSparkle.splashFactory,
""",
    """      scaffoldBackgroundColor: background,
      canvasColor: background,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme:
          reduceMotion
              ? const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android:
                      _NoTransitionsPageTransitionsBuilder(),
                  TargetPlatform.fuchsia:
                      _NoTransitionsPageTransitionsBuilder(),
                  TargetPlatform.iOS: _NoTransitionsPageTransitionsBuilder(),
                  TargetPlatform.linux: _NoTransitionsPageTransitionsBuilder(),
                  TargetPlatform.macOS: _NoTransitionsPageTransitionsBuilder(),
                  TargetPlatform.windows:
                      _NoTransitionsPageTransitionsBuilder(),
                },
              )
              : const PageTransitionsTheme(),
      splashFactory: InkSparkle.splashFactory,
""",
)
replace(
    'lib/core/theme/app_theme.dart',
    """      appBarTheme: AppBarTheme(
        centerTitle: false,
""",
    """      appBarTheme: AppBarTheme(
        toolbarHeight: toolbarHeight,
        centerTitle: false,
""",
)
replace(
    'lib/core/theme/app_theme.dart',
    """        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
""",
    """        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14 + textScaleDelta * 4,
        ),
""",
)
replace(
    'lib/core/theme/app_theme.dart',
    """      navigationBarTheme: NavigationBarThemeData(
        height: 72,
""",
    """      navigationBarTheme: NavigationBarThemeData(
        height: navigationBarHeight,
""",
)
replace(
    'lib/core/theme/app_theme.dart',
    """      listTileTheme: ListTileThemeData(
        minVerticalPadding: 10,
""",
    """      listTileTheme: ListTileThemeData(
        minVerticalPadding: 10 + textScaleDelta * 6,
""",
)
replace(
    'lib/core/theme/app_theme.dart',
    '          minimumSize: const Size(42, 42),\n',
    '          minimumSize: Size.square(iconButtonExtent),\n',
)
button_block = """          minimumSize:
              isTv
                  ? const Size(120, 56)
                  : isDesktopOrTv
                  ? const Size(92, 44)
                  : const Size(88, 48),
"""
button_replacement = """          minimumSize: Size(
            isTv
                ? 120
                : isDesktopOrTv
                ? 92
                : 88,
            buttonHeight,
          ),
"""
replace('lib/core/theme/app_theme.dart', button_block, button_replacement)
replace('lib/core/theme/app_theme.dart', button_block, button_replacement)
replace(
    'lib/core/theme/app_theme.dart',
    """          minimumSize:
              isTv
                  ? const Size(120, 56)
                  : isDesktopOrTv
                  ? const Size(88, 44)
                  : const Size(80, 44),
""",
    """          minimumSize: Size(
            isTv
                ? 120
                : isDesktopOrTv
                ? 88
                : 80,
            buttonHeight,
          ),
""",
)
theme_path = Path('lib/core/theme/app_theme.dart')
theme_text = theme_path.read_text()
if 'class _NoTransitionsPageTransitionsBuilder' not in theme_text:
    theme_path.write_text(
        theme_text
        + """

class _NoTransitionsPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
"""
    )

# Adaptive mini-player geometry and 48px play control.
replace(
    'lib/features/player/presentation/widgets/mini_player.dart',
    "import '../../../../core/theme/app_dimensions.dart';\n",
    "import '../../../../core/theme/accessibility.dart';\nimport '../../../../core/theme/app_dimensions.dart';\n",
)
replace(
    'lib/features/player/presentation/widgets/mini_player.dart',
    """    final tokens = SongloftThemeTokens.of(context);

    if (!state.hasSong) {
""",
    """    final tokens = SongloftThemeTokens.of(context);
    final textScaleFactor = AppAccessibility.textScaleOf(context);
    final textScaleDelta = textScaleFactor - 1.0;

    if (!state.hasSong) {
""",
)
replace(
    'lib/features/player/presentation/widgets/mini_player.dart',
    """    final height = _isCompact ? 54.0 : 76.0;
    final coverSize = _isCompact ? 38.0 : 54.0;
    final playButtonSize = _isCompact ? 38.0 : 46.0;
""",
    """    final height =
        (_isCompact ? 58.0 : 76.0) +
        textScaleDelta * (_isCompact ? 18.0 : 24.0);
    final coverSize = _isCompact ? 38.0 : 54.0;
    final playButtonSize = 48.0 + textScaleDelta * 4;
""",
)
replace(
    'lib/features/player/presentation/widgets/mini_player.dart',
    """                                icon: const Icon(Icons.skip_next_rounded),
                                visualDensity: VisualDensity.compact,
""",
    """                                icon: const Icon(Icons.skip_next_rounded),
""",
)

# Full-screen player routes and animations follow reduced motion.
for player_file in [
    'lib/features/player/presentation/widgets/mobile_player.dart',
    'lib/features/player/presentation/widgets/mobile_player_gesture_host.dart',
]:
    replace(
        player_file,
        "import '../../../../core/theme/app_dimensions.dart';\n"
        if player_file.endswith('mobile_player.dart')
        else "import 'package:flutter_riverpod/flutter_riverpod.dart';\n\n",
        "import '../../../../core/theme/accessibility.dart';\nimport '../../../../core/theme/app_dimensions.dart';\n"
        if player_file.endswith('mobile_player.dart')
        else "import 'package:flutter_riverpod/flutter_riverpod.dart';\n\nimport '../../../../core/theme/accessibility.dart';\n",
    )

replace(
    'lib/features/player/presentation/widgets/mobile_player_gesture_host.dart',
    """  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                const MobilePlayerGestureHost(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
""",
    """  static Future<void> show(BuildContext context) {
    final reduceMotion = AppAccessibility.reduceMotionOf(context);
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
        reverseTransitionDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                const MobilePlayerGestureHost(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (reduceMotion) return child;
          return SlideTransition(
""",
)
replace(
    'lib/features/player/presentation/widgets/mobile_player.dart',
    """  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder:
            (context, animation, secondaryAnimation) => const MobilePlayer(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 从下往上滑入动画
""",
    """  static Future<void> show(BuildContext context) {
    final reduceMotion = AppAccessibility.reduceMotionOf(context);
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
        reverseTransitionDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        pageBuilder:
            (context, animation, secondaryAnimation) => const MobilePlayer(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (reduceMotion) return child;
          // 从下往上滑入动画
""",
)
replace(
    'lib/features/player/presentation/widgets/mobile_player.dart',
    """    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
""",
    """    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final reduceMotion = AppAccessibility.reduceMotionOf(context);
""",
)
replace(
    'lib/features/player/presentation/widgets/mobile_player.dart',
    """      if (next.isPlaying && !_rotationController.isAnimating) {
        _rotationController.repeat();
      } else if (!next.isPlaying && _rotationController.isAnimating) {
        _rotationController.stop();
      }
""",
    """      if (!reduceMotion &&
          next.isPlaying &&
          !_rotationController.isAnimating) {
        _rotationController.repeat();
      } else if ((reduceMotion || !next.isPlaying) &&
          _rotationController.isAnimating) {
        _rotationController.stop();
      }
""",
)
replace(
    'lib/features/player/presentation/widgets/mobile_player.dart',
    """    if (state.isPlaying && !_rotationController.isAnimating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && state.isPlaying && !_rotationController.isAnimating) {
          _rotationController.repeat();
        }
      });
    }
""",
    """    if (!reduceMotion &&
        state.isPlaying &&
        !_rotationController.isAnimating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !AppAccessibility.reduceMotionOf(context) &&
            state.isPlaying &&
            !_rotationController.isAnimating) {
          _rotationController.repeat();
        }
      });
    }
""",
)
replace(
    'lib/features/player/presentation/widgets/mobile_player.dart',
    '              _isDragging ? Duration.zero : const Duration(milliseconds: 220),\n',
    """              _isDragging || reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
""",
)
replace(
    'lib/features/player/presentation/widgets/mobile_player.dart',
    '                      duration: const Duration(milliseconds: 800),\n',
    """                      duration: AppAccessibility.motionDuration(
                        context,
                        const Duration(milliseconds: 800),
                      ),
""",
)
replace(
    'lib/features/player/presentation/widgets/mobile_player.dart',
    '                    duration: const Duration(milliseconds: 500),\n',
    """                    duration: AppAccessibility.motionDuration(
                      context,
                      const Duration(milliseconds: 500),
                    ),
""",
)

# The decorative vinyl ring becomes static when reduced motion is enabled.
replace(
    'lib/features/player/presentation/widgets/vinyl_ring.dart',
    """    final grooveColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.06);

    return Stack(
""",
    """    final grooveColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.06);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final ring = Opacity(
      opacity: 0.5,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _VinylRingPainter(grooveColor: grooveColor),
        ),
      ),
    );

    return Stack(
""",
)
replace(
    'lib/features/player/presentation/widgets/vinyl_ring.dart',
    """          child: RotationTransition(
            turns: rotationAnimation,
            child: Opacity(
              opacity: 0.5,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _VinylRingPainter(grooveColor: grooveColor),
                ),
              ),
            ),
          ),
""",
    """          child:
              reduceMotion
                  ? ring
                  : RotationTransition(turns: rotationAnimation, child: ring),
""",
)

# Ensure the stacked PR runs the normal CI workflow.
replace(
    '.github/workflows/ui-redesign-check.yml',
    """      - mobile-fourth-round
    paths:
""",
    """      - mobile-fourth-round
      - mobile-fifth-round
    paths:
""",
)

# Focused regression coverage.
Path('test/core/theme/app_theme_accessibility_test.dart').write_text(
    """import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songloft_player/core/theme/accessibility.dart';
import 'package:songloft_player/core/theme/app_theme.dart';

void main() {
  test('mobile theme keeps primary controls at least 48 logical pixels', () {
    final theme = AppTheme.lightTheme();
    final states = <WidgetState>{};
    final iconSize = theme.iconButtonTheme.style?.minimumSize?.resolve(states);
    final filledSize =
        theme.filledButtonTheme.style?.minimumSize?.resolve(states);
    final textSize = theme.textButtonTheme.style?.minimumSize?.resolve(states);

    expect(iconSize?.width, greaterThanOrEqualTo(48));
    expect(iconSize?.height, greaterThanOrEqualTo(48));
    expect(filledSize?.height, greaterThanOrEqualTo(48));
    expect(textSize?.height, greaterThanOrEqualTo(48));
  });

  test('large system text expands navigation and control geometry', () {
    final normal = AppTheme.lightTheme(textScaleFactor: 1.0);
    final large = AppTheme.lightTheme(textScaleFactor: 1.8);
    final states = <WidgetState>{};

    expect(
      large.navigationBarTheme.height,
      greaterThan(normal.navigationBarTheme.height!),
    );
    expect(
      large.appBarTheme.toolbarHeight,
      greaterThan(normal.appBarTheme.toolbarHeight!),
    );
    expect(
      large.filledButtonTheme.style?.minimumSize?.resolve(states)?.height,
      greaterThan(
        normal.filledButtonTheme.style?.minimumSize?.resolve(states)?.height ??
            0,
      ),
    );
  });

  test('reduced motion theme installs no-transition builders', () {
    final theme = AppTheme.darkTheme(reduceMotion: true);
    for (final platform in TargetPlatform.values) {
      expect(
        theme.pageTransitionsTheme.builders[platform].runtimeType.toString(),
        contains('NoTransitionsPageTransitionsBuilder'),
      );
    }
  });

  testWidgets('system accessibility preferences are read and bounded', (
    tester,
  ) async {
    late double scale;
    late bool reduceMotion;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          textScaler: TextScaler.linear(2.6),
          disableAnimations: true,
        ),
        child: Builder(
          builder: (context) {
            scale = AppAccessibility.textScaleOf(context);
            reduceMotion = AppAccessibility.reduceMotionOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(scale, 2.0);
    expect(reduceMotion, isTrue);
  });
}
"""
)

print('sixth-round patch applied')
