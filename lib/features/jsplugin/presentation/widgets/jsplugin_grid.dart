import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/app_config.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/responsive.dart';
import '../../data/jsplugin_api.dart';
import '../providers/jsplugin_provider.dart';
import 'plugin_icon.dart';

/// JS 插件快捷入口网格
class JSPluginGrid extends ConsumerWidget {
  const JSPluginGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pluginsAsync = ref.watch(jsPluginsProvider);

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
                          '${activePlugins.length} 个扩展已启用',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                    itemCount: activePlugins.length,
                    itemBuilder: (context, index) {
                      return _JSPluginCard(plugin: activePlugins[index]);
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
