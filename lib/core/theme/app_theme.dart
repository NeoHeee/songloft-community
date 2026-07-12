import 'package:flutter/material.dart';

import 'app_dimensions.dart';
import 'responsive.dart';
import 'theme_pack.dart';
import 'theme_tokens.dart';

class AppTheme {
  /// 亮色主题
  static ThemeData lightTheme({
    ScreenType screenType = ScreenType.mobile,
    SongloftThemePack? themePack,
    double textScaleFactor = 1.0,
    bool reduceMotion = false,
  }) {
    return _buildTheme(
      Brightness.light,
      screenType,
      themePack ?? SongloftThemePacks.classic,
      textScaleFactor,
      reduceMotion,
    );
  }

  /// 暗色主题
  static ThemeData darkTheme({
    ScreenType screenType = ScreenType.mobile,
    SongloftThemePack? themePack,
    double textScaleFactor = 1.0,
    bool reduceMotion = false,
  }) {
    return _buildTheme(
      Brightness.dark,
      screenType,
      themePack ?? SongloftThemePacks.classic,
      textScaleFactor,
      reduceMotion,
    );
  }

  static ThemeData _buildTheme(
    Brightness brightness,
    ScreenType screenType,
    SongloftThemePack themePack,
    double textScaleFactor,
    bool reduceMotion,
  ) {
    final isDark = brightness == Brightness.dark;
    final isTv = screenType == ScreenType.tv;
    final isDesktopOrTv =
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
    final generatedScheme = ColorScheme.fromSeed(
      seedColor: palette.seedColor,
      brightness: brightness,
    );
    final colorScheme = generatedScheme.copyWith(
      secondary: palette.secondaryColor ?? generatedScheme.secondary,
      tertiary: palette.tertiaryColor ?? generatedScheme.tertiary,
      surface: palette.surfaceColor,
      onSurface: _foregroundFor(palette.surfaceColor),
    );
    final background = palette.backgroundColor;
    final panelColor = palette.surfaceColor;
    final cardRadius = palette.cardRadius;
    final controlRadius = palette.controlRadius;
    final navigationRadius = palette.navigationRadius;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
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
      fontFamilyFallback: const ['NotoSansSC', 'sans-serif'],
      extensions: [
        SongloftThemeTokens(
          playerGradient: palette.playerGradient,
          cardRadius: cardRadius,
          controlRadius: controlRadius,
          navigationRadius: navigationRadius,
        ),
      ],
      appBarTheme: AppBarTheme(
        toolbarHeight: toolbarHeight,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: panelColor,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.18 : 0.45,
            ),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.38 : 0.72,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14 + textScaleDelta * 4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: navigationBarHeight,
        elevation: 0,
        backgroundColor: panelColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.8),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(navigationRadius),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: panelColor,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.76),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(navigationRadius),
        ),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 10 + textScaleDelta * 6,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
        selectedColor: colorScheme.primary,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.48),
        iconColor: colorScheme.onSurfaceVariant,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Size.square(iconButtonExtent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(
            isTv
                ? 120
                : isDesktopOrTv
                ? 92
                : 88,
            buttonHeight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: TextStyle(
            fontSize: isTv ? 18 : 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(
            isTv
                ? 120
                : isDesktopOrTv
                ? 92
                : 88,
            buttonHeight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(
            isTv
                ? 120
                : isDesktopOrTv
                ? 88
                : 80,
            buttonHeight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: panelColor,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: panelColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular((cardRadius + 6).clamp(16, 40).toDouble()),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 12,
        backgroundColor: panelColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            (cardRadius + 2).clamp(12, 40).toDouble(),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF262A37) : const Color(0xFF252735),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isDesktopOrTv
                ? (isTv ? AppRadius.md : controlRadius)
                : controlRadius,
          ),
        ),
        insetPadding:
            isDesktopOrTv
                ? (isTv
                    ? const EdgeInsets.symmetric(horizontal: 48, vertical: 24)
                    : const EdgeInsets.symmetric(horizontal: 24, vertical: 12))
                : null,
        width: isDesktopOrTv ? (isTv ? 600 : 480) : null,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.18),
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        trackHeight: 3,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withValues(alpha: 0.14),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2B2E3B) : const Color(0xFF242634),
          borderRadius: BorderRadius.circular(
            (controlRadius - 4).clamp(6, 14).toDouble(),
          ),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static Color _foregroundFor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : const Color(0xFF15151A);
  }
}

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
