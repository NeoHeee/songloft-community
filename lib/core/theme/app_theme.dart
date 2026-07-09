import 'package:flutter/material.dart';

import 'app_dimensions.dart';
import 'responsive.dart';

class AppTheme {
  static const Color _seedColor = Color(0xFF7C5CFF);
  static const Color _darkBackground = Color(0xFF0B0D12);
  static const Color _lightBackground = Color(0xFFF4F5FA);

  /// 亮色主题
  static ThemeData lightTheme({ScreenType screenType = ScreenType.mobile}) {
    return _buildTheme(Brightness.light, screenType);
  }

  /// 暗色主题
  static ThemeData darkTheme({ScreenType screenType = ScreenType.mobile}) {
    return _buildTheme(Brightness.dark, screenType);
  }

  static ThemeData _buildTheme(Brightness brightness, ScreenType screenType) {
    final isDark = brightness == Brightness.dark;
    final isTv = screenType == ScreenType.tv;
    final isDesktopOrTv =
        screenType == ScreenType.desktop || screenType == ScreenType.tv;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );
    final background = isDark ? _darkBackground : _lightBackground;
    final panelColor = isDark
        ? const Color(0xFF151821)
        : const Color(0xFFFFFFFF);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashFactory: InkSparkle.splashFactory,
      fontFamilyFallback: const ['NotoSansSC', 'sans-serif'],
      appBarTheme: AppBarTheme(
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
          borderRadius: BorderRadius.circular(22),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: panelColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.8),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: panelColor,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.76),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        selectedColor: colorScheme.primary,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.48),
        iconColor: colorScheme.onSurfaceVariant,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(42, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: isTv
              ? const Size(120, 56)
              : isDesktopOrTv
              ? const Size(92, 44)
              : const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: TextStyle(
            fontSize: isTv ? 18 : 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: isTv
              ? const Size(120, 56)
              : isDesktopOrTv
              ? const Size(92, 44)
              : const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: isTv
              ? const Size(120, 56)
              : isDesktopOrTv
              ? const Size(88, 44)
              : const Size(80, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: panelColor,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: panelColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 12,
        backgroundColor: panelColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF262A37)
            : const Color(0xFF252735),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isDesktopOrTv ? (isTv ? AppRadius.md : AppRadius.sm) : AppRadius.sm,
          ),
        ),
        insetPadding: isDesktopOrTv
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
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
