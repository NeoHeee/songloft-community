import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/theme_catalog.dart';
import '../../../../core/theme/theme_catalog_provider.dart';
import '../../../../core/theme/theme_catalog_repository.dart';
import '../../../../core/theme/theme_pack.dart';
import '../../../../core/theme/theme_pack_provider.dart';
import '../../../../shared/utils/responsive_snackbar.dart';

Future<void> showThemeCatalogDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const ThemeCatalogDialog(),
  );
}

class ThemeCatalogDialog extends ConsumerStatefulWidget {
  const ThemeCatalogDialog({super.key});

  @override
  ConsumerState<ThemeCatalogDialog> createState() => _ThemeCatalogDialogState();
}

class _ThemeCatalogDialogState extends ConsumerState<ThemeCatalogDialog> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedTag;
  String? _downloadingId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(themeCatalogProvider);
    ref.watch(themePackProvider);
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 720;

    return Dialog(
      insetPadding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: compact ? BorderRadius.zero : AppRadius.lgAll,
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: compact ? size.width : 960,
        height: compact
            ? size.height
            : size.height.clamp(620.0, 820.0).toDouble(),
        child: Column(
          children: [
            _buildHeader(context, catalogState, compact),
            Expanded(
              child: catalogState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _CatalogError(
                  message: '$error',
                  onRetry: () =>
                      ref.read(themeCatalogProvider.notifier).refreshCatalog(),
                ),
                data: (catalog) => _buildCatalog(context, catalog),
              ),
            ),
            _buildSecurityFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<ThemeCatalog> state,
    bool compact,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? AppSpacing.md : AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
              ),
              borderRadius: AppRadius.mdAll,
            ),
            child: const Icon(Icons.storefront_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '在线主题目录',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  '浏览、校验并手动安装社区主题',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: state.isLoading
                ? null
                : () =>
                      ref.read(themeCatalogProvider.notifier).refreshCatalog(),
            tooltip: '刷新目录',
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: '关闭',
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalog(BuildContext context, ThemeCatalog catalog) {
    final entries = _filteredEntries(catalog.entries);
    final tags = <String>{
      for (final entry in catalog.entries) ...entry.tags,
    }.toList()..sort();

    return Column(
      children: [
        _CatalogOriginBanner(catalog: catalog),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '搜索主题、作者、简介或标签',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      tooltip: '清除搜索',
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ),
        if (tags.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('全部'),
                  selected: _selectedTag == null,
                  onSelected: (_) => setState(() => _selectedTag = null),
                ),
                const SizedBox(width: AppSpacing.sm),
                for (final tag in tags) ...[
                  ChoiceChip(
                    label: Text(tag),
                    selected: _selectedTag == tag,
                    onSelected: (_) => setState(
                      () => _selectedTag = _selectedTag == tag ? null : tag,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: entries.isEmpty
              ? const _CatalogEmpty()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 3
                        : constraints.maxWidth >= 580
                        ? 2
                        : 1;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      itemCount: entries.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        mainAxisExtent: 310,
                      ),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _CatalogThemeCard(
                          entry: entry,
                          installed: _installedPack(entry.id),
                          downloading: _downloadingId == entry.id,
                          onInstall: () => _installTheme(entry),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSecurityFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '仅允许受信任 HTTPS 来源；下载后校验 SHA-256 和主题身份，安装前仍需确认。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ThemeCatalogEntry> _filteredEntries(List<ThemeCatalogEntry> entries) {
    final query = _searchController.text.trim().toLowerCase();
    return entries
        .where((entry) {
          if (_selectedTag != null && !entry.tags.contains(_selectedTag)) {
            return false;
          }
          if (query.isEmpty) return true;
          final haystack = [
            entry.name,
            entry.author,
            entry.description,
            entry.id,
            ...entry.tags,
          ].join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  SongloftThemePack? _installedPack(String id) {
    for (final pack in ref.read(themePackProvider).customPacks) {
      if (pack.id == id) return pack;
    }
    return null;
  }

  Future<void> _installTheme(ThemeCatalogEntry entry) async {
    if (_downloadingId != null) return;
    setState(() => _downloadingId = entry.id);
    try {
      final download = await ref
          .read(themeCatalogProvider.notifier)
          .downloadTheme(entry);
      if (!mounted) return;
      final existing = _installedPack(entry.id);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => _CatalogInstallDialog(
          download: download,
          isUpdate: existing != null,
        ),
      );
      if (confirmed != true || !mounted) return;

      final installed = await ref
          .read(themePackProvider.notifier)
          .installThemePack(download.source);
      if (!mounted) return;
      ResponsiveSnackBar.showSuccess(
        context,
        message: existing == null
            ? '主题“${installed.name}”已安装并启用'
            : '主题“${installed.name}”已更新并启用',
      );
    } catch (error) {
      if (!mounted) return;
      ResponsiveSnackBar.showError(context, message: '安装失败：$error');
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }
}

class _CatalogOriginBanner extends StatelessWidget {
  final ThemeCatalog catalog;

  const _CatalogOriginBanner({required this.catalog});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final remote = catalog.origin == ThemeCatalogOrigin.remote;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: remote
            ? colorScheme.primaryContainer.withValues(alpha: 0.45)
            : colorScheme.tertiaryContainer.withValues(alpha: 0.55),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Icon(
            remote ? Icons.cloud_done_rounded : Icons.offline_bolt_rounded,
            color: remote
                ? colorScheme.onPrimaryContainer
                : colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              remote
                  ? '已连接 ${catalog.name}，共 ${catalog.entries.length} 个主题。'
                  : '远程目录暂不可用，当前显示内置安全快照；可稍后点击刷新。',
              style: TextStyle(
                color: remote
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogThemeCard extends StatelessWidget {
  final ThemeCatalogEntry entry;
  final SongloftThemePack? installed;
  final bool downloading;
  final VoidCallback onInstall;

  const _CatalogThemeCard({
    required this.entry,
    required this.installed,
    required this.downloading,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sameVersion = installed?.version == entry.version;
    final isUpdate = installed != null && !sameVersion;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CatalogThemePreview(pack: entry.previewPack),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (entry.featured)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Text(
                      '精选',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '${entry.author} · v${entry.version}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Text(
                entry.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: entry.tags
                  .take(3)
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: sameVersion || downloading ? null : onInstall,
                icon: downloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        sameVersion
                            ? Icons.check_circle_rounded
                            : isUpdate
                            ? Icons.system_update_alt_rounded
                            : Icons.download_rounded,
                      ),
                label: Text(
                  downloading
                      ? '校验中'
                      : sameVersion
                      ? '已安装'
                      : isUpdate
                      ? '更新主题'
                      : '预览并安装',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogThemePreview extends StatelessWidget {
  final SongloftThemePack pack;
  final double height;

  const _CatalogThemePreview({required this.pack, this.height = 92});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.mdAll,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(child: _CatalogPalettePreview(palette: pack.light)),
            Expanded(child: _CatalogPalettePreview(palette: pack.dark)),
          ],
        ),
      ),
    );
  }
}

class _CatalogPalettePreview extends StatelessWidget {
  final SongloftThemePalette palette;

  const _CatalogPalettePreview({required this.palette});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: palette.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: palette.playerGradient),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: palette.surfaceColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 18,
                  height: 12,
                  decoration: BoxDecoration(
                    color: palette.seedColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogInstallDialog extends StatelessWidget {
  final ThemeCatalogDownload download;
  final bool isUpdate;

  const _CatalogInstallDialog({required this.download, required this.isUpdate});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pack = download.pack;
    final sourceLabel = download.origin == ThemeCatalogOrigin.remote
        ? '受信任在线目录'
        : '内置安全副本';

    return AlertDialog(
      title: Text(isUpdate ? '确认更新主题' : '确认安装主题'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'SHA-256 完整性和主题身份校验已通过',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: pack.light.playerGradient,
                      ),
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: const Icon(
                      Icons.palette_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pack.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${pack.author} · v${pack.version}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _CatalogThemePreview(pack: pack, height: 150),
              const SizedBox(height: AppSpacing.md),
              _CatalogMetadataRow(label: '主题 ID', value: pack.id),
              _CatalogMetadataRow(label: '来源', value: sourceLabel),
              _CatalogMetadataRow(
                label: '校验值',
                value: '${download.sha256Digest.substring(0, 20)}…',
              ),
              if (pack.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  pack.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (isUpdate) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  '已安装相同主题 ID，确认后会覆盖原版本并立即启用。',
                  style: TextStyle(color: colorScheme.tertiary),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: Icon(
            isUpdate ? Icons.system_update_alt_rounded : Icons.download_rounded,
          ),
          label: Text(isUpdate ? '更新并启用' : '安装并启用'),
        ),
      ],
    );
  }
}

class _CatalogMetadataRow extends StatelessWidget {
  final String label;
  final String value;

  const _CatalogMetadataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CatalogError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '主题目录加载失败',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重新加载'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogEmpty extends StatelessWidget {
  const _CatalogEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text('没有找到符合条件的主题'),
        ],
      ),
    );
  }
}
