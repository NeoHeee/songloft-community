import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/app_config.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/responsive.dart';
import '../../data/jsplugin_api.dart';
import '../providers/jsplugin_provider.dart';
import 'plugin_icon.dart';

/// 首页插件入口隐藏状态。仅控制首页展示，不改变插件启用状态。
final homePluginHiddenEntriesProvider =
    AsyncNotifierProvider<HomePluginHiddenEntriesNotifier, Set<String>>(
      HomePluginHiddenEntriesNotifier.new,
    );

class HomePluginHiddenEntriesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final prefs = await AppPreferences.create();
    return prefs.getHiddenHomePluginEntries();
  }

  Future<void> setVisible(String entryPath, {required bool visible}) async {
    final current = state.value ?? const <String>{};
    final next = <String>{...current};
    if (visible) {
      next.remove(entryPath);
    } else {
      next.add(entryPath);
    }
    state = AsyncData(next);
    final prefs = await AppPreferences.create();
    await prefs.setHiddenHomePluginEntries(next);
  }

  Future<void> showAll() async {
    state = const AsyncData<Set<String>>(<String>{});
    final prefs = await AppPreferences.create();
    await prefs.setHiddenHomePluginEntries(const <String>{});
  }
}

/// JS 插件快捷入口网格
class JSPluginGrid extends ConsumerWidget {
  const JSPluginGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pluginsAsync = ref.watch(jsPluginsProvider);
    final hiddenEntriesAsync = ref.watch(homePluginHiddenEntriesProvider);

    return pluginsAsync.when(
      data: (plugins) {
        final activePlugins = plugins
            .where(
              (plugin) =>
                  plugin.isActive &&
                  plugin.entryPath != null &&
                  plugin.entryPath!.isNotEmpty,
            )
            .toList();

        if (activePlugins.isEmpty) {
          return const SizedBox.shrink();
        }

        final hiddenEntries = hiddenEntriesAsync.value ?? const <String>{};
        final visiblePlugins = activePlugins
            .where((plugin) => !hiddenEntries.contains(plugin.entryPath))
            .toList();
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withValues(
                        alpha: 0.72,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.extension_rounded,
                      color: colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '插件快捷入口',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${visiblePlugins.length} 个显示 · ${activePlugins.length} 个已启用',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: '选择快捷入口',
                    onPressed: () =>
                        _showVisibilitySheet(context, activePlugins),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (visiblePlugins.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 22,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.42,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.visibility_off_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '已隐藏全部快捷入口',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '点击右上角调节按钮可重新显示',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final int crossAxisCount;
                    if (context.isMobile ||
                        width < ResponsiveBreakpoints.tablet) {
                      crossAxisCount = (width / 104).floor().clamp(2, 4);
                    } else if (width < ResponsiveBreakpoints.desktop) {
                      crossAxisCount = (width / 128).floor().clamp(4, 5);
                    } else {
                      crossAxisCount = (width / 150).floor().clamp(4, 7);
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: visiblePlugins.length,
                      itemBuilder: (context, index) {
                        return _JSPluginCard(plugin: visiblePlugins[index]);
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _showVisibilitySheet(BuildContext context, List<JSPlugin> plugins) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PluginVisibilitySheet(plugins: plugins),
    );
  }
}

class _PluginVisibilitySheet extends ConsumerWidget {
  final List<JSPlugin> plugins;

  const _PluginVisibilitySheet({required this.plugins});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hiddenEntriesAsync = ref.watch(homePluginHiddenEntriesProvider);
    final hiddenEntries = hiddenEntriesAsync.value ?? const <String>{};

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '选择首页快捷入口',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '隐藏后插件仍保持启用，可随时重新显示',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: hiddenEntries.isEmpty
                        ? null
                        : () => ref
                              .read(homePluginHiddenEntriesProvider.notifier)
                              .showAll(),
                    child: const Text('全部显示'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: plugins.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 76),
                itemBuilder: (context, index) {
                  final plugin = plugins[index];
                  final entryPath = plugin.entryPath!;
                  final visible = !hiddenEntries.contains(entryPath);
                  return SwitchListTile(
                    value: visible,
                    onChanged: hiddenEntriesAsync.isLoading
                        ? null
                        : (value) => ref
                              .read(homePluginHiddenEntriesProvider.notifier)
                              .setVisible(entryPath, visible: value),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 2,
                    ),
                    secondary: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: PluginIcon(
                        iconUrl: plugin.iconUrl,
                        displayName: plugin.displayName,
                        size: 34,
                      ),
                    ),
                    title: Text(
                      plugin.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: plugin.version == null || plugin.version!.isEmpty
                        ? const Text('已启用')
                        : Text('版本 ${plugin.version}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JSPluginCard extends StatelessWidget {
  final JSPlugin plugin;

  const _JSPluginCard({required this.plugin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPlugin(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 13, 10, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: PluginIcon(
                  iconUrl: plugin.iconUrl,
                  displayName: plugin.displayName,
                  size: 46,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                plugin.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (plugin.version != null) ...[
                const SizedBox(height: 4),
                Text(
                  'v${plugin.version}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openPlugin(BuildContext context) {
    if (plugin.entryPath == null || plugin.entryPath!.isEmpty) {
      return;
    }

    final url =
        '${AppConfig.baseUrl}${AppConfig.basePath}/api/v1/jsplugin/${plugin.entryPath}';
    final theme = Theme.of(context).brightness == Brightness.dark
        ? 'dark'
        : 'light';

    if (kIsWeb) {
      final token = SecureStorageService.cachedAccessToken ?? '';
      final params = <String>['theme=$theme'];
      if (token.isNotEmpty) params.add('access_token=$token');
      final webUrl = Uri.parse('$url?${params.join('&')}');
      launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      context.push(
        Uri(
          path: AppRoutes.plugin,
          queryParameters: {'url': url, 'name': plugin.displayName},
        ).toString(),
      );
    }
  }
}
