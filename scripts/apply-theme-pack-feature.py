from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding="utf-8")
    if old not in text:
        raise SystemExit(f"Expected text not found in {path}: {old[:120]!r}")
    file.write_text(text.replace(old, new, 1), encoding="utf-8")


main = "lib/main.dart"
replace_once(
    main,
    "import 'core/theme/app_theme.dart';\nimport 'core/theme/responsive.dart';",
    "import 'core/theme/app_theme.dart';\n"
    "import 'core/theme/responsive.dart';\n"
    "import 'core/theme/theme_pack_provider.dart';",
)
replace_once(
    main,
    "    final themeMode = ref.watch(themeModeProvider);\n"
    "    return MaterialApp.router(",
    "    final themeMode = ref.watch(themeModeProvider);\n"
    "    final themePack = ref.watch(themePackProvider).selectedPack;\n"
    "    return MaterialApp.router(",
)
replace_once(
    main,
    "      theme: AppTheme.lightTheme(),\n"
    "      darkTheme: AppTheme.darkTheme(),",
    "      theme: AppTheme.lightTheme(themePack: themePack),\n"
    "      darkTheme: AppTheme.darkTheme(themePack: themePack),",
)
replace_once(
    main,
    "          data: isDark\n"
    "              ? AppTheme.darkTheme(screenType: screenType)\n"
    "              : AppTheme.lightTheme(screenType: screenType),",
    "          data: isDark\n"
    "              ? AppTheme.darkTheme(\n"
    "                  screenType: screenType,\n"
    "                  themePack: themePack,\n"
    "                )\n"
    "              : AppTheme.lightTheme(\n"
    "                  screenType: screenType,\n"
    "                  themePack: themePack,\n"
    "                ),",
)

settings = "lib/features/settings/presentation/settings_page.dart"
replace_once(
    settings,
    "import 'widgets/theme_selector.dart';",
    "import 'widgets/theme_selector.dart';\n"
    "import 'widgets/theme_pack_manager.dart';",
)
replace_once(
    settings,
    "            child: ThemeSelector(),\n"
    "          ),\n"
    "        ],\n"
    "      ),",
    "            child: ThemeSelector(),\n"
    "          ),\n"
    "          Divider(height: 1),\n"
    "          ThemePackManager(),\n"
    "        ],\n"
    "      ),",
)

shell = "lib/shared/layouts/redesigned_desktop_shell.dart"
replace_once(
    shell,
    "import '../../core/theme/responsive.dart';",
    "import '../../core/theme/responsive.dart';\n"
    "import '../../core/theme/theme_tokens.dart';",
)
replace_once(
    shell,
    "    final colorScheme = Theme.of(context).colorScheme;\n\n"
    "    return Scaffold(",
    "    final colorScheme = Theme.of(context).colorScheme;\n"
    "    final tokens = SongloftThemeTokens.of(context);\n\n"
    "    return Scaffold(",
)
replace_once(
    shell,
    "              colorScheme.primary.withValues(alpha: 0.055),\n"
    "              Theme.of(context).scaffoldBackgroundColor,\n"
    "              colorScheme.tertiary.withValues(alpha: 0.035),",
    "              tokens.playerGradient[0].withValues(alpha: 0.07),\n"
    "              Theme.of(context).scaffoldBackgroundColor,\n"
    "              tokens.playerGradient[1].withValues(alpha: 0.05),",
)
replace_once(
    shell,
    "                              borderRadius: BorderRadius.circular(26),",
    "                              borderRadius: BorderRadius.circular(\n"
    "                                (tokens.cardRadius + 4)\n"
    "                                    .clamp(14, 40)\n"
    "                                    .toDouble(),\n"
    "                              ),",
)
replace_once(
    shell,
    "    final theme = Theme.of(context);\n"
    "    final colorScheme = theme.colorScheme;\n\n"
    "    return Container(\n"
    "      width: compact ? 94 : 256,",
    "    final theme = Theme.of(context);\n"
    "    final colorScheme = theme.colorScheme;\n"
    "    final tokens = SongloftThemeTokens.of(context);\n\n"
    "    return Container(\n"
    "      width: compact ? 94 : 256,",
)
replace_once(
    shell,
    "        borderRadius: BorderRadius.circular(28),",
    "        borderRadius: BorderRadius.circular(\n"
    "          (tokens.cardRadius + 6).clamp(16, 40).toDouble(),\n"
    "        ),",
)
replace_once(
    shell,
    "    final theme = Theme.of(context);\n"
    "    final colorScheme = theme.colorScheme;\n\n"
    "    return Padding(\n"
    "      padding: EdgeInsets.fromLTRB(compact ? 17 : 20, 22, compact ? 17 : 20, 8),",
    "    final theme = Theme.of(context);\n"
    "    final colorScheme = theme.colorScheme;\n"
    "    final tokens = SongloftThemeTokens.of(context);\n\n"
    "    return Padding(\n"
    "      padding: EdgeInsets.fromLTRB(compact ? 17 : 20, 22, compact ? 17 : 20, 8),",
)
replace_once(
    shell,
    "                colors: [colorScheme.primary, colorScheme.tertiary],",
    "                colors: tokens.playerGradient,",
)

mini = "lib/features/player/presentation/widgets/mini_player.dart"
replace_once(
    mini,
    "import '../../../../core/theme/app_dimensions.dart';",
    "import '../../../../core/theme/app_dimensions.dart';\n"
    "import '../../../../core/theme/theme_tokens.dart';",
)
replace_once(
    mini,
    "    final colorScheme = theme.colorScheme;\n\n"
    "    if (!state.hasSong) {",
    "    final colorScheme = theme.colorScheme;\n"
    "    final tokens = SongloftThemeTokens.of(context);\n\n"
    "    if (!state.hasSong) {",
)
replace_once(
    mini,
    "        borderRadius: BorderRadius.circular(22),",
    "        borderRadius: BorderRadius.circular(tokens.cardRadius),",
)
