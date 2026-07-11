from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding='utf-8')


def write(path: str, text: str) -> None:
    (ROOT / path).write_text(text, encoding='utf-8')


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f'missing patch anchor: {label}')
    return text.replace(old, new, 1)


def patch_tv_theme() -> None:
    path = 'lib/core/theme/tv_theme.dart'
    text = read(path)
    if 'static const double iconSizeSmall' in text:
        return
    text = replace_once(
        text,
        '  /// 按钮最小尺寸\n  static const double minButtonSize = 80;\n',
        '''  /// 按钮最小尺寸
  static const double minButtonSize = 80;

  /// TV 图标尺寸层级
  static const double iconSizeSmall = 24;
  static const double iconSizeMedium = 32;
  static const double iconSizeLarge = 40;
  static const double iconSizeHero = 56;

  /// TV 图标底板尺寸层级
  static const double iconSurfaceSmall = 48;
  static const double iconSurfaceMedium = 64;
  static const double iconSurfaceLarge = 80;
  static const double iconSurfaceRadius = 18;
''',
        'TV icon constants',
    )
    write(path, text)


def patch_app_theme() -> None:
    path = 'lib/core/theme/app_theme.dart'
    text = read(path)
    if 'iconTheme: IconThemeData(' in text:
        return
    text = replace_once(
        text,
        "      fontFamilyFallback: const ['NotoSansSC', 'sans-serif'],\n",
        '''      fontFamilyFallback: const ['NotoSansSC', 'sans-serif'],
      iconTheme: IconThemeData(
        size: isTv ? 32 : 24,
        color: colorScheme.onSurfaceVariant,
      ),
      primaryIconTheme: IconThemeData(
        size: isTv ? 32 : 24,
        color: colorScheme.primary,
      ),
''',
        'global icon theme',
    )
    text = replace_once(
        text,
        '        selectedIconTheme: IconThemeData(color: colorScheme.primary),\n',
        '''        selectedIconTheme: IconThemeData(
          color: colorScheme.primary,
          size: isTv ? 34 : 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: isTv ? 32 : 24,
        ),
''',
        'navigation rail icon sizes',
    )
    text = replace_once(
        text,
        '          minimumSize: const Size(42, 42),\n',
        '''          minimumSize: isTv ? const Size(56, 56) : const Size(42, 42),
          iconSize: isTv ? 30 : 24,
''',
        'icon button TV size',
    )
    write(path, text)


def patch_tv_focusable() -> None:
    path = 'lib/shared/widgets/tv_focusable.dart'
    text = read(path)
    if 'final Color? focusIconColor;' in text:
        return
    text = replace_once(
        text,
        '  /// 是否显示焦点阴影\n  final bool showShadow;\n',
        '''  /// 是否显示焦点阴影
  final bool showShadow;

  /// 获得焦点时，为未显式指定颜色的 Icon 提供统一高亮色
  final Color? focusIconColor;

  /// 未获得焦点时的图标色；为空时沿用子组件自身样式
  final Color? unfocusedIconColor;
''',
        'TvFocusable icon fields',
    )
    text = replace_once(
        text,
        '    this.showShadow = true,\n    this.borderRadius = 12,\n',
        '''    this.showShadow = true,
    this.focusIconColor,
    this.unfocusedIconColor,
    this.borderRadius = 12,
''',
        'TvFocusable icon constructor',
    )
    text = replace_once(
        text,
        '                child: widget.child,\n',
        '''                child: IconTheme.merge(
                  data: IconThemeData(
                    color: _hasFocus
                        ? (widget.focusIconColor ?? focusBorderColor)
                        : widget.unfocusedIconColor,
                  ),
                  child: widget.child,
                ),
''',
        'TvFocusable focused icon theme',
    )
    write(path, text)


def patch_tv_home() -> None:
    path = 'lib/features/home/presentation/tv_home_page.dart'
    text = read(path)
    if "shared/widgets/tv_icon_surface.dart" not in text:
        text = replace_once(
            text,
            "import '../../../shared/widgets/tv_focusable.dart';\n",
            "import '../../../shared/widgets/tv_focusable.dart';\nimport '../../../shared/widgets/tv_icon_surface.dart';\n",
            'TV home icon surface import',
        )

    text = text.replace('size: 28,', 'size: TvTheme.iconSizeMedium,')
    text = text.replace('size: 48,', 'size: TvTheme.iconSizeLarge,')
    text = text.replace('size: 56,', 'size: TvTheme.iconSizeHero,')
    text = text.replace('size: 80,', 'size: TvTheme.iconSurfaceLarge,')

    old_delegate = '''gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: TvTheme.gridColumns,
                    mainAxisSpacing: TvTheme.gridSpacing,
                    crossAxisSpacing: TvTheme.gridSpacing,
                    childAspectRatio: 0.85,
                  ),'''
    new_delegate = '''gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 310,
                    mainAxisSpacing: TvTheme.gridSpacing,
                    crossAxisSpacing: TvTheme.gridSpacing,
                    childAspectRatio: 0.85,
                  ),'''
    if old_delegate not in text:
        raise RuntimeError('missing TV home grid delegate')
    text = text.replace(old_delegate, new_delegate)

    text = replace_once(
        text,
        '            Icon(icon, size: TvTheme.iconSizeLarge, color: colorScheme.primary),\n',
        '''            TvIconSurface(
              size: TvTheme.iconSurfaceMedium,
              iconSize: TvTheme.iconSizeLarge,
              accentColor: colorScheme.primary,
              icon: Icon(icon),
            ),
''',
        'TV quick navigation icon',
    )

    old_placeholder = '''        child: Icon(
          playlist.type == 'radio'
              ? Icons.radio_rounded
              : Icons.queue_music_rounded,
          size: TvTheme.iconSizeHero,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),'''
    new_placeholder = '''        child: TvIconSurface(
          size: TvTheme.iconSurfaceLarge,
          iconSize: TvTheme.iconSizeHero,
          accentColor: playlist.type == 'radio'
              ? colorScheme.secondary
              : colorScheme.primary,
          icon: Icon(
            playlist.type == 'radio'
                ? Icons.radio_rounded
                : Icons.queue_music_rounded,
          ),
        ),'''
    text = replace_once(text, old_placeholder, new_placeholder, 'TV cover placeholder')
    write(path, text)


def patch_settings_icons() -> None:
    path = 'lib/features/settings/presentation/widgets/settings_master_detail.dart'
    text = read(path)
    if "shared/widgets/tv_icon_surface.dart" not in text:
        text = replace_once(
            text,
            "import '../../../../shared/widgets/tv_focusable.dart';\n",
            "import '../../../../shared/widgets/tv_focusable.dart';\nimport '../../../../shared/widgets/tv_icon_surface.dart';\n",
            'settings icon surface import',
        )

    old = '''          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color:
                  selected
                      ? colorScheme.primary.withValues(alpha: 0.16)
                      : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              category.icon,
              size: 30,
              color:
                  selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),'''
    new = '''          TvIconSurface(
            size: TvTheme.iconSurfaceMedium,
            iconSize: TvTheme.iconSizeMedium,
            selected: selected,
            accentColor: colorScheme.primary,
            icon: Icon(category.icon),
          ),'''
    text = replace_once(text, old, new, 'settings TV category icon')
    write(path, text)


def patch_plugin_registry() -> None:
    path = 'lib/features/jsplugin/presentation/widgets/plugin_registry.dart'
    text = read(path)
    if "../../../../config/app_config.dart" not in text:
        text = replace_once(
            text,
            "import 'package:flutter_svg/flutter_svg.dart';\n\n",
            "import 'package:flutter_svg/flutter_svg.dart';\n\nimport '../../../../config/app_config.dart';\n",
            'plugin registry AppConfig import',
        )
    if "../../../../core/theme/tv_theme.dart" not in text:
        text = replace_once(
            text,
            "import '../../../../core/theme/app_dimensions.dart';\n",
            "import '../../../../core/theme/app_dimensions.dart';\nimport '../../../../core/theme/tv_theme.dart';\n",
            'plugin registry TvTheme import',
        )
    if "../../../../shared/widgets/tv_focusable.dart" not in text:
        text = replace_once(
            text,
            "import '../../../../shared/utils/responsive_snackbar.dart';\n",
            "import '../../../../shared/utils/responsive_snackbar.dart';\nimport '../../../../shared/widgets/tv_focusable.dart';\n",
            'plugin registry TvFocusable import',
        )
    if "import 'plugin_icon.dart';" not in text:
        text = replace_once(
            text,
            "import '../providers/jsplugin_provider.dart';\n",
            "import '../providers/jsplugin_provider.dart';\nimport 'plugin_icon.dart';\n",
            'plugin icon import',
        )

    text = replace_once(
        text,
        '''                 (context, index) => _RegistryPluginItem(
                   entry: plugins[index],
''',
        '''                 (context, index) => _RegistryPluginItem(
                   entry: plugins[index],
                   autofocus: AppConfig.isTvMode && index == 0,
''',
        'plugin item autofocus',
    )

    old_list = '''        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: plugins.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
            itemBuilder:
                (context, index) => _RegistryPluginItem(
                  entry: plugins[index],
                  autofocus: AppConfig.isTvMode && index == 0,
                  githubProxy: _effectiveProxy,
                  token: _selectedRegistry?.token ?? '',
                  onInstalled: () {
                    _refreshPlugins();
                    ref.invalidate(jsPluginsProvider);
                  },
                ),
          ),
        ),'''
    new_list = '''        Expanded(
          child: AppConfig.isTvMode
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1500
                        ? 4
                        : constraints.maxWidth >= 980
                            ? 3
                            : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        TvTheme.contentPadding,
                        18,
                        TvTheme.contentPadding,
                        120,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 1.42,
                      ),
                      itemCount: plugins.length,
                      itemBuilder: (context, index) => _RegistryPluginItem(
                        entry: plugins[index],
                        autofocus: index == 0,
                        githubProxy: _effectiveProxy,
                        token: _selectedRegistry?.token ?? '',
                        onInstalled: () {
                          _refreshPlugins();
                          ref.invalidate(jsPluginsProvider);
                        },
                      ),
                    );
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: plugins.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
                  itemBuilder: (context, index) => _RegistryPluginItem(
                    entry: plugins[index],
                    githubProxy: _effectiveProxy,
                    token: _selectedRegistry?.token ?? '',
                    onInstalled: () {
                      _refreshPlugins();
                      ref.invalidate(jsPluginsProvider);
                    },
                  ),
                ),
        ),'''
    text = replace_once(text, old_list, new_list, 'TV plugin grid')

    text = replace_once(
        text,
        '  final VoidCallback onInstalled;\n',
        '  final VoidCallback onInstalled;\n  final bool autofocus;\n',
        'plugin item autofocus field',
    )
    text = replace_once(
        text,
        "    this.token = '',\n    required this.onInstalled,\n  });",
        "    this.token = '',\n    required this.onInstalled,\n    this.autofocus = false,\n  });",
        'plugin item autofocus constructor',
    )

    old_build = '''    return ListTile(
      leading: _buildIcon(entry, theme),
      title: Text(entry.name),'''
    new_build = '''    if (AppConfig.isTvMode) {
      return _buildTvCard(entry, theme);
    }

    return ListTile(
      leading: PluginIcon(
        iconUrl: entry.icon,
        displayName: entry.name,
        size: 48,
      ),
      title: Text(entry.name),'''
    text = replace_once(text, old_build, new_build, 'plugin item TV card switch')

    insert_anchor = '  Widget _buildIcon(RegistryPluginEntry entry, ThemeData theme) {'
    tv_card = '''  Widget _buildTvCard(RegistryPluginEntry entry, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final actionLabel = entry.installed
        ? (entry.hasUpdate ? '更新至 v${entry.version}' : '重新安装')
        : '安装';

    return TvFocusable(
      autofocus: widget.autofocus,
      onSelect: _installing ? null : _install,
      focusedScale: 1.025,
      borderRadius: 22,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PluginIcon(
                  iconUrl: entry.icon,
                  displayName: entry.name,
                  size: 72,
                  selected: entry.installed,
                  statusColor: entry.installed ? colorScheme.primary : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        entry.author?.isNotEmpty == true
                            ? entry.author!
                            : 'Songloft 插件',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Text(
                entry.description?.isNotEmpty == true
                    ? entry.description!
                    : '暂无插件说明',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: entry.installed
                    ? colorScheme.primaryContainer.withValues(alpha: 0.64)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_installing)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  else
                    Icon(
                      entry.hasUpdate
                          ? Icons.system_update_alt_rounded
                          : entry.installed
                              ? Icons.refresh_rounded
                              : Icons.download_rounded,
                      size: TvTheme.iconSizeSmall,
                      color: colorScheme.primary,
                    ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      _installing ? '正在处理…' : actionLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

'''
    text = replace_once(text, insert_anchor, tv_card + insert_anchor, 'TV plugin card method')

    start = text.index('  Widget _buildIcon(RegistryPluginEntry entry, ThemeData theme) {')
    end = text.index('  Widget _buildAction(', start)
    replacement = '''  Widget _buildIcon(RegistryPluginEntry entry, ThemeData theme) {
    return PluginIcon(
      iconUrl: entry.icon,
      displayName: entry.name,
      size: 48,
      selected: entry.installed,
      statusColor: entry.installed ? theme.colorScheme.primary : null,
    );
  }

'''
    text = text[:start] + replacement + text[end:]
    write(path, text)


def main() -> None:
    patch_tv_theme()
    patch_app_theme()
    patch_tv_focusable()
    patch_tv_home()
    patch_settings_icons()
    patch_plugin_registry()
    print('TV icon polish applied')


if __name__ == '__main__':
    main()
