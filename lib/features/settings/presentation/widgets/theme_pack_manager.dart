import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/theme_pack.dart';
import '../../../../core/theme/theme_pack_provider.dart';
import '../../../../shared/utils/responsive_snackbar.dart';

class ThemePackManager extends ConsumerWidget {
  const ThemePackManager({super.key});

  static const String themePackTemplate = '''{
  "schemaVersion": 1,
  "id": "my-theme-pack",
  "name": "我的主题",
  "version": "1.0.0",
  "author": "作者名称",
  "description": "主题简介",
  "light": {
    "seed": "#7C5CFF",
    "background": "#F4F5FA",
    "surface": "#FFFFFF",
    "secondary": "#4C7DFF",
    "tertiary": "#B45CFF",
    "playerGradient": ["#7C5CFF", "#4C7DFF"],
    "cardRadius": 22,
    "controlRadius": 15,
    "navigationRadius": 16
  },
  "dark": {
    "seed": "#9C87FF",
    "background": "#0B0D12",
    "surface": "#151821",
    "secondary": "#6E9BFF",
    "tertiary": "#D18AFF",
    "playerGradient": ["#8B6CFF", "#426FE8"],
    "cardRadius": 22,
    "controlRadius": 15,
    "navigationRadius": 16
  }
}''';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(themePackProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '主题包',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '导入前先预览；导出或复制 JSON 后可分享给其他用户',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showThemePackGuide(context),
                tooltip: '主题包制作规范',
                icon: const Icon(Icons.help_outline_rounded),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 184,
          child:
              state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: state.packs.length,
                    separatorBuilder:
                        (_, _) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final pack = state.packs[index];
                      return _ThemePackCard(
                        pack: pack,
                        selected: pack.id == state.selectedId,
                        onSelected: () => _selectTheme(context, ref, pack),
                        onAction:
                            (action) =>
                                _handlePackAction(context, ref, pack, action),
                      );
                    },
                  ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: () => _importThemePack(context, ref),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('导入主题包'),
              ),
              OutlinedButton.icon(
                onPressed:
                    state.isLoading
                        ? null
                        : () => _exportThemePack(context, state.selectedPack),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('导出当前主题'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showThemePackGuide(context),
                icon: const Icon(Icons.description_outlined),
                label: const Text('制作规范'),
              ),
            ],
          ),
        ),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Text(
              state.errorMessage!,
              style: TextStyle(color: colorScheme.error),
            ),
          ),
      ],
    );
  }

  Future<void> _selectTheme(
    BuildContext context,
    WidgetRef ref,
    SongloftThemePack pack,
  ) async {
    try {
      await ref.read(themePackProvider.notifier).selectThemePack(pack.id);
    } catch (e) {
      if (!context.mounted) return;
      ResponsiveSnackBar.showError(context, message: '切换主题失败：$e');
    }
  }

  Future<void> _importThemePack(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['songloft-theme', 'json'],
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw const ThemePackFormatException('未能读取主题包内容');
      }
      if (bytes.length > ThemePackNotifier.maxThemePackBytes) {
        throw const ThemePackFormatException('主题包不能超过 128 KB');
      }

      var source = utf8.decode(bytes);
      if (source.startsWith('\uFEFF')) {
        source = source.substring(1);
      }

      final pack = SongloftThemePack.fromJsonString(source);
      if (SongloftThemePacks.findBuiltIn(pack.id) != null) {
        throw const ThemePackFormatException('自定义主题包不能使用内置主题的 id');
      }

      final currentState = ref.read(themePackProvider);
      final isUpdate = currentState.customPacks.any(
        (installed) => installed.id == pack.id,
      );
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => _ThemeImportPreviewDialog(
              pack: pack,
              fileName: file.name,
              isUpdate: isUpdate,
            ),
      );
      if (confirmed != true || !context.mounted) return;

      final installed = await ref
          .read(themePackProvider.notifier)
          .installThemePack(source);
      if (!context.mounted) return;
      ResponsiveSnackBar.showSuccess(
        context,
        message:
            isUpdate
                ? '主题包“${installed.name}”已更新并启用'
                : '主题包“${installed.name}”已安装并启用',
      );
    } catch (e) {
      if (!context.mounted) return;
      ResponsiveSnackBar.showError(context, message: '导入失败：$e');
    }
  }

  Future<void> _handlePackAction(
    BuildContext context,
    WidgetRef ref,
    SongloftThemePack pack,
    _ThemePackAction action,
  ) async {
    switch (action) {
      case _ThemePackAction.details:
        await showDialog<void>(
          context: context,
          builder: (_) => _ThemePackDetailsDialog(pack: pack),
        );
        break;
      case _ThemePackAction.copyJson:
        await _copyThemeJson(context, pack);
        break;
      case _ThemePackAction.export:
        await _exportThemePack(context, pack);
        break;
      case _ThemePackAction.delete:
        await _confirmDelete(context, ref, pack);
        break;
    }
  }

  Future<void> _copyThemeJson(
    BuildContext context,
    SongloftThemePack pack,
  ) async {
    await Clipboard.setData(ClipboardData(text: '${pack.toPrettyJson()}\n'));
    if (!context.mounted) return;
    ResponsiveSnackBar.showSuccess(
      context,
      message: '“${pack.name}”的主题 JSON 已复制',
    );
  }

  Future<void> _exportThemePack(
    BuildContext context,
    SongloftThemePack pack,
  ) async {
    try {
      final content = '${pack.toPrettyJson()}\n';
      final bytes = Uint8List.fromList(utf8.encode(content));
      final fileName = '${_safeFileName(pack.id)}.songloft-theme';
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出 Songloft 主题包',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['songloft-theme'],
        bytes: bytes,
      );
      if (outputPath == null || !context.mounted) return;
      ResponsiveSnackBar.showSuccess(context, message: '主题包“${pack.name}”已导出');
    } catch (e) {
      if (!context.mounted) return;
      ResponsiveSnackBar.showError(context, message: '导出失败：$e');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SongloftThemePack pack,
  ) async {
    if (pack.isBuiltIn) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('删除主题包'),
            content: Text('确定删除“${pack.name}”吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('删除'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(themePackProvider.notifier).removeThemePack(pack.id);
      if (!context.mounted) return;
      ResponsiveSnackBar.showSuccess(context, message: '主题包已删除');
    } catch (e) {
      if (!context.mounted) return;
      ResponsiveSnackBar.showError(context, message: '删除失败：$e');
    }
  }

  void _showThemePackGuide(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('主题包制作规范'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 560),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '主题包是 UTF-8 编码的 JSON 文件，建议扩展名使用 '
                    '.songloft-theme。主题包不允许脚本、CSS、远程链接或可执行代码。',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _GuideLine(text: 'schemaVersion 当前固定为 1'),
                  const _GuideLine(text: 'id 使用小写字母、数字、点、下划线或短横线，长度 3-64'),
                  const _GuideLine(text: 'light 和 dark 必须同时提供'),
                  const _GuideLine(text: '颜色使用 #RRGGBB 或 #AARRGGBB；圆角范围为 0-40'),
                  const _GuideLine(text: '单个主题包最大 128 KB，最多安装 32 个'),
                  const _GuideLine(text: '同一自定义 id 再次导入会显示更新提示'),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: const SelectableText(
                      themePackTemplate,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  const ClipboardData(text: themePackTemplate),
                );
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(const SnackBar(content: Text('模板已复制')));
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('复制模板'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('完成'),
            ),
          ],
        );
      },
    );
  }

  String _safeFileName(String id) {
    final sanitized = id.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '-');
    return sanitized.isEmpty ? 'songloft-theme' : sanitized;
  }
}

enum _ThemePackAction { details, copyJson, export, delete }

class _ThemePackCard extends StatelessWidget {
  final SongloftThemePack pack;
  final bool selected;
  final VoidCallback onSelected;
  final ValueChanged<_ThemePackAction> onAction;

  const _ThemePackCard({
    required this.pack,
    required this.selected,
    required this.onSelected,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: pack.name,
      child: InkWell(
        onTap: onSelected,
        borderRadius: AppRadius.lgAll,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 218,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color:
                selected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.38)
                    : colorScheme.surfaceContainerLow,
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color:
                  selected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.45),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThemePreview(pack: pack),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pack.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 19,
                      color: colorScheme.primary,
                    ),
                  PopupMenuButton<_ThemePackAction>(
                    tooltip: '主题操作',
                    padding: EdgeInsets.zero,
                    onSelected: onAction,
                    itemBuilder:
                        (_) => [
                          const PopupMenuItem(
                            value: _ThemePackAction.details,
                            child: ListTile(
                              leading: Icon(Icons.info_outline_rounded),
                              title: Text('查看详情'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: _ThemePackAction.copyJson,
                            child: ListTile(
                              leading: Icon(Icons.copy_all_rounded),
                              title: Text('复制 JSON'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: _ThemePackAction.export,
                            child: ListTile(
                              leading: Icon(Icons.ios_share_rounded),
                              title: Text('导出主题包'),
                            ),
                          ),
                          if (!pack.isBuiltIn)
                            const PopupMenuItem(
                              value: _ThemePackAction.delete,
                              child: ListTile(
                                leading: Icon(Icons.delete_outline_rounded),
                                title: Text('删除'),
                              ),
                            ),
                        ],
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                  ),
                ],
              ),
              Text(
                '${pack.isBuiltIn ? '内置' : '自定义'} · ${pack.author} · v${pack.version}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeImportPreviewDialog extends StatelessWidget {
  final SongloftThemePack pack;
  final String fileName;
  final bool isUpdate;

  const _ThemeImportPreviewDialog({
    required this.pack,
    required this.fileName,
    required this.isUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(isUpdate ? '更新主题包' : '安装主题包'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isUpdate)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.system_update_alt_rounded,
                        color: colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '已安装相同 id 的主题，确认后将覆盖原版本。',
                          style: TextStyle(
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _ThemePackSummary(pack: pack),
              const SizedBox(height: AppSpacing.md),
              _ThemePreview(pack: pack, height: 150),
              const SizedBox(height: AppSpacing.md),
              _MetadataRow(label: '文件', value: fileName),
              _MetadataRow(label: '主题 ID', value: pack.id),
              _MetadataRow(label: '规范', value: 'v${pack.schemaVersion}'),
              if (pack.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  pack.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
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

class _ThemePackDetailsDialog extends StatelessWidget {
  final SongloftThemePack pack;

  const _ThemePackDetailsDialog({required this.pack});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('主题包详情'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 620),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThemePackSummary(pack: pack),
              const SizedBox(height: AppSpacing.md),
              _ThemePreview(pack: pack, height: 160),
              const SizedBox(height: AppSpacing.lg),
              _MetadataRow(label: '主题 ID', value: pack.id),
              _MetadataRow(label: '规范版本', value: '${pack.schemaVersion}'),
              _MetadataRow(
                label: '类型',
                value: pack.isBuiltIn ? 'Songloft 内置主题' : '自定义主题包',
              ),
              if (pack.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  pack.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                '浅色配色',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PaletteDetails(palette: pack.light),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '深色配色',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PaletteDetails(palette: pack.dark),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('完成'),
        ),
      ],
    );
  }
}

class _ThemePackSummary extends StatelessWidget {
  final SongloftThemePack pack;

  const _ThemePackSummary({required this.pack});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: pack.light.playerGradient),
            borderRadius: AppRadius.mdAll,
          ),
          child: const Icon(Icons.palette_rounded, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pack.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${pack.author} · v${pack.version}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final SongloftThemePack pack;
  final double height;

  const _ThemePreview({required this.pack, this.height = 88});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.mdAll,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: _PalettePreview(
                palette: pack.light,
                label: '浅色',
                expanded: height > 100,
              ),
            ),
            Expanded(
              child: _PalettePreview(
                palette: pack.dark,
                label: '深色',
                expanded: height > 100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PalettePreview extends StatelessWidget {
  final SongloftThemePalette palette;
  final String label;
  final bool expanded;

  const _PalettePreview({
    required this.palette,
    required this.label,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        ThemeData.estimateBrightnessForColor(palette.backgroundColor) ==
                Brightness.dark
            ? Colors.white
            : const Color(0xFF17171D);
    return ColoredBox(
      color: palette.backgroundColor,
      child: Padding(
        padding: EdgeInsets.all(expanded ? 14 : 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expanded) ...[
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
            ],
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: palette.playerGradient),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    expanded
                        ? const Center(
                          child: Icon(
                            Icons.graphic_eq_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 13,
                    decoration: BoxDecoration(
                      color: palette.surfaceColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 18,
                  height: 13,
                  decoration: BoxDecoration(
                    color: palette.seedColor,
                    borderRadius: BorderRadius.circular(5),
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

class _PaletteDetails extends StatelessWidget {
  final SongloftThemePalette palette;

  const _PaletteDetails({required this.palette});

  @override
  Widget build(BuildContext context) {
    final colors = <(String, Color)>[
      ('主色', palette.seedColor),
      ('背景', palette.backgroundColor),
      ('面板', palette.surfaceColor),
      if (palette.secondaryColor != null) ('辅助', palette.secondaryColor!),
      if (palette.tertiaryColor != null) ('第三色', palette.tertiaryColor!),
      ('渐变 1', palette.playerGradient[0]),
      ('渐变 2', palette.playerGradient[1]),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: colors
              .map((entry) => _ColorChip(label: entry.$1, color: entry.$2))
              .toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '卡片圆角 ${palette.cardRadius.toStringAsFixed(0)} · '
          '控件圆角 ${palette.controlRadius.toStringAsFixed(0)} · '
          '导航圆角 ${palette.navigationRadius.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ColorChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ColorChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final hex =
        color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
            ),
          ),
          const SizedBox(width: 7),
          Text('$label  #$hex', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
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

class _GuideLine extends StatelessWidget {
  final String text;

  const _GuideLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 5),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
