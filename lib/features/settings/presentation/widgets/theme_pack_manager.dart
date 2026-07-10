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
                      '选择内置主题，或导入统一规范的 .songloft-theme 文件',
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
          height: 178,
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  scrollDirection: Axis.horizontal,
                  itemCount: state.packs.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final pack = state.packs[index];
                    return _ThemePackCard(
                      pack: pack,
                      selected: pack.id == state.selectedId,
                      onSelected: () => _selectTheme(context, ref, pack),
                      onDelete: pack.isBuiltIn
                          ? null
                          : () => _confirmDelete(context, ref, pack),
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
      final pack = await ref
          .read(themePackProvider.notifier)
          .installThemePack(source);
      if (!context.mounted) return;
      ResponsiveSnackBar.showSuccess(
        context,
        message: '主题包“${pack.name}”已安装并启用',
      );
    } catch (e) {
      if (!context.mounted) return;
      ResponsiveSnackBar.showError(context, message: '导入失败：$e');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SongloftThemePack pack,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
                  const _GuideLine(
                    text: 'id 使用小写字母、数字、点、下划线或短横线，长度 3-64',
                  ),
                  const _GuideLine(text: 'light 和 dark 必须同时提供'),
                  const _GuideLine(
                    text: '颜色使用 #RRGGBB 或 #AARRGGBB；圆角范围为 0-40',
                  ),
                  const _GuideLine(text: '单个主题包最大 128 KB，最多安装 32 个'),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: SelectableText(
                      themePackTemplate,
                      style: const TextStyle(
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
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('模板已复制')),
                );
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
}

class _ThemePackCard extends StatelessWidget {
  final SongloftThemePack pack;
  final bool selected;
  final VoidCallback onSelected;
  final VoidCallback? onDelete;

  const _ThemePackCard({
    required this.pack,
    required this.selected,
    required this.onSelected,
    this.onDelete,
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
          width: 208,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.38)
                : colorScheme.surfaceContainerLow,
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: selected
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
                  if (onDelete != null)
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: onDelete,
                        tooltip: '删除主题包',
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      ),
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

class _ThemePreview extends StatelessWidget {
  final SongloftThemePack pack;

  const _ThemePreview({required this.pack});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.mdAll,
      child: SizedBox(
        height: 88,
        child: Row(
          children: [
            Expanded(child: _PalettePreview(palette: pack.light)),
            Expanded(child: _PalettePreview(palette: pack.dark)),
          ],
        ),
      ),
    );
  }
}

class _PalettePreview extends StatelessWidget {
  final SongloftThemePalette palette;

  const _PalettePreview({required this.palette});

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
