import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/theme/responsive.dart';
import '../../../../shared/utils/responsive_snackbar.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/jsplugin_api.dart';
import '../providers/jsplugin_provider.dart';
import 'plugin_icon.dart';

class _JSProxyOption {
  final String label;
  final String value;

  const _JSProxyOption({required this.label, required this.value});
}

const List<_JSProxyOption> _kGithubProxies = [
  _JSProxyOption(label: '直连（不使用代理）', value: ''),
  _JSProxyOption(label: 'ghproxy.com', value: 'https://ghproxy.com/'),
  _JSProxyOption(label: 'ghfast.top', value: 'https://ghfast.top/'),
  _JSProxyOption(label: 'gh.con.sh', value: 'https://gh.con.sh/'),
  _JSProxyOption(
    label: 'mirror.ghproxy.com',
    value: 'https://mirror.ghproxy.com/',
  ),
];

/// 已安装 JS 插件管理器。
///
/// 本组件位于设置页“扩展”分组中，因此直接展示内容，不再额外嵌套 ExpansionTile。
class JSPluginManager extends ConsumerStatefulWidget {
  const JSPluginManager({super.key});

  @override
  ConsumerState<JSPluginManager> createState() => _JSPluginManagerState();
}

class _JSPluginManagerState extends ConsumerState<JSPluginManager> {
  final _searchController = TextEditingController();
  String _query = '';
  String _status = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pluginsAsync = ref.watch(jsPluginsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(15),
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
                      '已安装插件',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '管理启用状态、常驻运行和版本更新',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => ref.invalidate(jsPluginsProvider),
                icon: const Icon(Icons.refresh_rounded),
                tooltip: '刷新列表',
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 650;
              final search = _buildSearchField(context);
              final actions = _buildActions(context);

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    search,
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: actions,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 10),
                  actions,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          pluginsAsync.when(
            data: (plugins) => _buildPluginContent(context, plugins),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _PluginLoadError(
              message: error is ApiException ? error.message : '$error',
              onRetry: () => ref.invalidate(jsPluginsProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '搜索插件名称、作者或功能描述',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.close_rounded),
                tooltip: '清除搜索',
              ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      onChanged: (value) => setState(() => _query = value.trim()),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.tonalIcon(
          onPressed: _showUploadDialog,
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('上传'),
        ),
        const SizedBox(width: 7),
        OutlinedButton.icon(
          onPressed: _showBatchUpdateDialog,
          icon: const Icon(Icons.system_update_alt_rounded),
          label: const Text('全部更新'),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          tooltip: '更多维护操作',
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (value) {
            if (value == 'cleanup') _cleanupOrphanStorage();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'cleanup',
              child: ListTile(
                leading: Icon(Icons.cleaning_services_rounded),
                title: Text('清理卸载残留数据'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPluginContent(BuildContext context, List<JSPlugin> plugins) {
    final active = plugins.where((plugin) => plugin.isActive).length;
    final errors = plugins.where((plugin) => plugin.isError).length;
    final inactive = plugins.length - active - errors;
    final filtered = plugins.where((plugin) {
      final query = _query.toLowerCase();
      final matchesQuery = query.isEmpty ||
          plugin.displayName.toLowerCase().contains(query) ||
          (plugin.author?.toLowerCase().contains(query) ?? false) ||
          (plugin.description?.toLowerCase().contains(query) ?? false);
      final matchesStatus = switch (_status) {
        'active' => plugin.isActive,
        'inactive' => !plugin.isActive && !plugin.isError,
        'error' => plugin.isError,
        _ => true,
      };
      return matchesQuery && matchesStatus;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StatusFilterChip(
                label: '全部',
                count: plugins.length,
                selected: _status == 'all',
                onTap: () => setState(() => _status = 'all'),
              ),
              _StatusFilterChip(
                label: '已启用',
                count: active,
                selected: _status == 'active',
                onTap: () => setState(() => _status = 'active'),
              ),
              _StatusFilterChip(
                label: '已禁用',
                count: inactive,
                selected: _status == 'inactive',
                onTap: () => setState(() => _status = 'inactive'),
              ),
              if (errors > 0)
                _StatusFilterChip(
                  label: '异常',
                  count: errors,
                  selected: _status == 'error',
                  error: true,
                  onTap: () => setState(() => _status = 'error'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (plugins.isEmpty)
          const _EmptyPlugins()
        else if (filtered.isEmpty)
          const _NoPluginResults()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 2 : 1;
              final itemWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final plugin in filtered)
                    SizedBox(
                      width: itemWidth,
                      child: _JSPluginCard(plugin: plugin),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => _JSPluginUploadDialog(
        pluginApi: ref.read(jsPluginApiProvider),
        onUploadComplete: () => ref.invalidate(jsPluginsProvider),
      ),
    );
  }

  void _showBatchUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _JSPluginBatchUpdateDialog(
        pluginApi: ref.read(jsPluginApiProvider),
        onUpdateComplete: () => ref.invalidate(jsPluginsProvider),
      ),
    );
  }

  Future<void> _cleanupOrphanStorage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理卸载残留数据'),
        content: const Text('将删除已卸载插件遗留的持久化存储数据。此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('开始清理'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final message = await ref.read(jsPluginApiProvider).cleanupOrphanStorage();
      if (mounted) ResponsiveSnackBar.showSuccess(context, message: message);
    } on ApiException catch (error) {
      if (mounted) {
        ResponsiveSnackBar.showError(
          context,
          message: '清理失败：${error.message}',
        );
      }
    } catch (error) {
      if (mounted) {
        ResponsiveSnackBar.showError(context, message: '清理失败：$error');
      }
    }
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final bool error;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = error ? colorScheme.error : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.14)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? accent : colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.16)
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: selected ? accent : colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JSPluginCard extends ConsumerStatefulWidget {
  final JSPlugin plugin;

  const _JSPluginCard({required this.plugin});

  @override
  ConsumerState<_JSPluginCard> createState() => _JSPluginCardState();
}

class _JSPluginCardState extends ConsumerState<_JSPluginCard> {
  bool _toggling = false;
  bool _deleting = false;
  bool _forceUpdating = false;

  @override
  Widget build(BuildContext context) {
    final plugin = widget.plugin;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final keepAlive = ref.watch(pluginKeepAliveProvider).value ?? <String>[];
    final isKeepAlive = keepAlive.contains(plugin.entryPath);
    final statusColor = plugin.isError
        ? colorScheme.error
        : plugin.isActive
            ? Colors.green
            : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: plugin.isError
              ? colorScheme.error.withValues(alpha: 0.35)
              : colorScheme.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(6),
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
                child: PluginIcon(
                  iconUrl: plugin.iconUrl,
                  displayName: plugin.displayName,
                  size: 46,
                  statusColor: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plugin.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _PluginStatusBadge(plugin: plugin),
                        if (plugin.version?.isNotEmpty == true)
                          _MetaBadge(label: 'v${plugin.version}'),
                        if (isKeepAlive)
                          const _MetaBadge(
                            label: '常驻',
                            icon: Icons.push_pin_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              _toggling
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Switch(
                      value: plugin.isActive,
                      onChanged: (_) => _togglePlugin(),
                    ),
            ],
          ),
          if (plugin.description?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              plugin.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          if (plugin.author?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    plugin.author!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 13),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.24),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              if (plugin.isActive)
                IconButton.filledTonal(
                  onPressed: _toggleKeepAlive,
                  icon: Icon(
                    isKeepAlive
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    size: 20,
                  ),
                  tooltip: isKeepAlive ? '取消常驻运行' : '设为常驻运行',
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showUpdateDialog,
                icon: const Icon(Icons.system_update_alt_rounded, size: 19),
                label: const Text('检查更新'),
              ),
              PopupMenuButton<String>(
                tooltip: '更多操作',
                icon: _forceUpdating || _deleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.more_horiz_rounded),
                onSelected: (value) {
                  switch (value) {
                    case 'homepage':
                      _openHomepage();
                    case 'force_update':
                      _forceUpdate();
                    case 'delete':
                      _deletePlugin();
                  }
                },
                itemBuilder: (context) => [
                  if (plugin.homepage?.isNotEmpty == true)
                    const PopupMenuItem(
                      value: 'homepage',
                      child: ListTile(
                        leading: Icon(Icons.open_in_new_rounded),
                        title: Text('打开插件主页'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'force_update',
                    child: ListTile(
                      leading: Icon(Icons.refresh_rounded),
                      title: Text('强制重新安装'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: colorScheme.error,
                      ),
                      title: Text(
                        '删除插件',
                        style: TextStyle(color: colorScheme.error),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _togglePlugin() async {
    setState(() => _toggling = true);
    try {
      final api = ref.read(jsPluginApiProvider);
      if (widget.plugin.isActive) {
        await api.disablePlugin(widget.plugin.id);
      } else {
        await api.enablePlugin(widget.plugin.id);
      }
      ref.invalidate(jsPluginsProvider);
    } on ApiException catch (error) {
      if (mounted) {
        ResponsiveSnackBar.showError(
          context,
          message: '操作失败：${error.message}',
        );
      }
    } catch (error) {
      if (mounted) {
        ResponsiveSnackBar.showError(context, message: '操作失败：$error');
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _toggleKeepAlive() async {
    final entryPath = widget.plugin.entryPath;
    if (entryPath == null || entryPath.isEmpty) return;

    final current = ref.read(pluginKeepAliveProvider).value ?? <String>[];
    final updated = current.contains(entryPath)
        ? current.where((item) => item != entryPath).toList()
        : [...current, entryPath];

    try {
      await ref.read(settingsApiProvider).setPluginKeepAlive(updated);
      ref.invalidate(pluginKeepAliveProvider);
    } on ApiException catch (error) {
      if (mounted) {
        ResponsiveSnackBar.showError(
          context,
          message: '操作失败：${error.message}',
        );
      }
    } catch (error) {
      if (mounted) {
        ResponsiveSnackBar.showError(context, message: '操作失败：$error');
      }
    }
  }

  Future<void> _openHomepage() async {
    final homepage = widget.plugin.homepage;
    if (homepage == null || homepage.isEmpty) return;
    final uri = Uri.tryParse(homepage);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ResponsiveSnackBar.showError(context, message: '无法打开插件主页');
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => _JSPluginUpdateDialog(
        plugin: widget.plugin,
        pluginApi: ref.read(jsPluginApiProvider),
        onUpdateComplete: () => ref.invalidate(jsPluginsProvider),
      ),
    );
  }

  Future<void> _forceUpdate() async {
    final proxy = await showDialog<String>(
      context: context,
      builder: (context) => _ProxyConfirmDialog(
        title: '强制重新安装',
        description: '将忽略版本检查，重新下载并安装“${widget.plugin.displayName}”。',
        confirmLabel: '开始安装',
      ),
    );
    if (proxy == null || !mounted) return;

    setState(() => _forceUpdating = true);
    try {
      await ref.read(jsPluginApiProvider).updatePlugin(
            widget.plugin.id,
            githubProxy: proxy.isEmpty ? null : proxy,
            force: true,
          );
      ref.invalidate(jsPluginsProvider);
      if (mounted) {
        ResponsiveSnackBar.showSuccess(context, message: '插件已重新安装');
      }
    } on ApiException catch (error) {
      if (mounted) {
        ResponsiveSnackBar.showError(
          context,
          message: '重新安装失败：${error.message}',
        );
      }
    } catch (error) {
      if (mounted) {
        ResponsiveSnackBar.showError(context, message: '重新安装失败：$error');
      }
    } finally {
      if (mounted) setState(() => _forceUpdating = false);
    }
  }

  Future<void> _deletePlugin() async {
    final result = await showDialog<({bool confirmed, bool keepData})>(
      context: context,
      builder: (context) {
        var keepData = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('删除插件'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('确定删除“${widget.plugin.displayName}”吗？'),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: keepData,
                  onChanged: (value) {
                    setDialogState(() => keepData = value ?? false);
                  },
                  title: const Text('保留插件数据'),
                  subtitle: const Text('以后重新安装时可继续使用原有设置和数据'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  (confirmed: false, keepData: false),
                ),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  (confirmed: true, keepData: keepData),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
    );
    if (result == null || !result.confirmed) return;

    setState(() => _deleting = true);
    try {
      await ref.read(jsPluginApiProvider).deletePlugin(
            widget.plugin.id,
            keepData: result.keepData,
          );
      ref.invalidate(jsPluginsProvider);
      if (mounted) {
        ResponsiveSnackBar.showSuccess(context, message: '插件已删除');
      }
    } on ApiException catch (error) {
      if (mounted) {
        ResponsiveSnackBar.showError(
          context,
          message: '删除失败：${error.message}',
        );
      }
    } catch (error) {
      if (mounted) {
        ResponsiveSnackBar.showError(context, message: '删除失败：$error');
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}

class _PluginStatusBadge extends StatelessWidget {
  final JSPlugin plugin;

  const _PluginStatusBadge({required this.plugin});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = plugin.isError
        ? ('异常', colorScheme.error)
        : plugin.isActive
            ? ('已启用', Colors.green)
            : ('已禁用', colorScheme.onSurfaceVariant);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _MetaBadge({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _JSPluginUploadDialog extends StatefulWidget {
  final JSPluginApi pluginApi;
  final VoidCallback onUploadComplete;

  const _JSPluginUploadDialog({
    required this.pluginApi,
    required this.onUploadComplete,
  });

  @override
  State<_JSPluginUploadDialog> createState() => _JSPluginUploadDialogState();
}

class _JSPluginUploadDialogState extends State<_JSPluginUploadDialog> {
  PlatformFile? _selectedFile;
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.upload_file_rounded),
          SizedBox(width: 9),
          Text('上传 JS 插件'),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.responsiveDialogMaxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '请选择以 .jsplugin.zip 结尾的插件包。上传同名插件会覆盖现有版本，插件数据默认保留。',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Material(
              color: _selectedFile == null
                  ? colorScheme.surfaceContainerLow
                  : colorScheme.primaryContainer.withValues(alpha: 0.36),
              borderRadius: BorderRadius.circular(19),
              child: InkWell(
                onTap: _uploading ? null : _pickFile,
                borderRadius: BorderRadius.circular(19),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 25,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: _selectedFile == null
                          ? colorScheme.outlineVariant
                          : colorScheme.primary,
                      width: _selectedFile == null ? 1 : 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile == null
                            ? Icons.cloud_upload_outlined
                            : Icons.inventory_2_rounded,
                        size: 45,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 9),
                      Text(
                        _selectedFile?.name ?? '点击选择插件包',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedFile == null
                            ? '仅支持 ZIP 格式'
                            : _formatFileSize(_selectedFile!.size),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _uploading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _selectedFile == null || _uploading ? null : _uploadFile,
          icon: _uploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.upload_rounded),
          label: Text(_uploading ? '正在上传' : '上传插件'),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: kIsWeb,
      );
      if (result != null && result.files.isNotEmpty && mounted) {
        setState(() => _selectedFile = result.files.first);
      }
    } catch (error) {
      if (mounted) {
        ResponsiveSnackBar.showError(context, message: '选择文件失败：$error');
      }
    }
  }

  Future<void> _uploadFile() async {
    final file = _selectedFile;
    if (file == null) return;
    setState(() => _uploading = true);

    try {
      final JSPluginUploadResponse response;
      if (kIsWeb) {
        if (file.bytes == null) {
          throw ApiException(message: '无法读取文件数据');
        }
        response = await widget.pluginApi.uploadPluginBytes(
          file.bytes!,
          file.name,
        );
      } else {
        if (file.path == null) {
          throw ApiException(message: '无法获取文件路径');
        }
        response = await widget.pluginApi.uploadPlugin(file.path!, file.name);
      }

      if (!mounted) return;
      widget.onUploadComplete();
      Navigator.pop(context);

      if (response.failed == 0 && response.success > 0) {
        ResponsiveSnackBar.showSuccess(
          context,
          message: response.message.isEmpty
              ? '成功上传 ${response.success} 个插件'
              : response.message,
        );
      } else {
        final details = response.results
            .where((item) => !item.success)
            .map((item) => '${item.fileName}：${item.error ?? '未知错误'}')
            .join('\n');
        ResponsiveSnackBar.showError(
          context,
          message: '成功 ${response.success} 个，失败 ${response.failed} 个\n$details',
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ResponsiveSnackBar.showError(
          context,
          message: '上传失败：${error.message}',
        );
      }
    } catch (error) {
      if (mounted) {
        ResponsiveSnackBar.showError(context, message: '上传失败：$error');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _JSPluginUpdateDialog extends StatefulWidget {
  final JSPlugin plugin;
  final JSPluginApi pluginApi;
  final VoidCallback onUpdateComplete;

  const _JSPluginUpdateDialog({
    required this.plugin,
    required this.pluginApi,
    required this.onUpdateComplete,
  });

  @override
  State<_JSPluginUpdateDialog> createState() => _JSPluginUpdateDialogState();
}

class _JSPluginUpdateDialogState extends State<_JSPluginUpdateDialog> {
  int _proxyIndex = 0;
  final _customProxyController = TextEditingController();
  bool _checking = false;
  bool _updating = false;
  String? _error;
  JSPluginUpdateCheck? _result;

  String get _proxy => _proxyIndex == -1
      ? _customProxyController.text.trim()
      : _kGithubProxies[_proxyIndex].value;

  @override
  void dispose() {
    _customProxyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          PluginIcon(
            iconUrl: widget.plugin.iconUrl,
            displayName: widget.plugin.displayName,
            size: 34,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '更新 ${widget.plugin.displayName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: context.responsiveDialogMaxWidth,
          maxHeight: MediaQuery.sizeOf(context).height * 0.62,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_updating) ...[
                _ProxySelector(
                  selectedIndex: _proxyIndex,
                  customController: _customProxyController,
                  onChanged: (value) => setState(() => _proxyIndex = value),
                ),
                const SizedBox(height: 14),
              ],
              if (_error != null)
                _MessagePanel(
                  icon: Icons.error_outline_rounded,
                  message: _error!,
                  color: colorScheme.error,
                ),
              if (_checking || _updating)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 14),
                      Text(_updating ? '正在下载并安装插件…' : '正在检查远程版本…'),
                    ],
                  ),
                )
              else if (_result != null)
                _buildResult(context, _result!),
            ],
          ),
        ),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildResult(BuildContext context, JSPluginUpdateCheck result) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!result.hasUpdate) {
      return _MessagePanel(
        icon: Icons.verified_rounded,
        message: '当前已是最新版本：v${result.currentVersion}',
        color: Colors.green,
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '发现新版本',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MetaBadge(label: 'v${result.currentVersion}'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 9),
                child: Icon(Icons.arrow_forward_rounded, size: 18),
              ),
              _MetaBadge(label: 'v${result.remoteVersion}'),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    if (_updating) return [];
    if (_checking) {
      return [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ];
    }

    if (_result?.hasUpdate == true) {
      return [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        OutlinedButton(onPressed: _checkUpdate, child: const Text('重新检查')),
        FilledButton(onPressed: _executeUpdate, child: const Text('立即更新')),
      ];
    }

    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(_result == null && _error == null ? '取消' : '关闭'),
      ),
      FilledButton(
        onPressed: _checkUpdate,
        child: Text(_result == null && _error == null ? '检查更新' : '重新检查'),
      ),
    ];
  }

  Future<void> _checkUpdate() async {
    setState(() {
      _checking = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await widget.pluginApi
          .checkUpdate(
            widget.plugin.id,
            githubProxy: _proxy.isEmpty ? null : _proxy,
          )
          .timeout(const Duration(seconds: 20));
      if (mounted) setState(() => _result = result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on TimeoutException {
      if (mounted) setState(() => _error = '检查超时，请切换代理后重试');
    } catch (error) {
      if (mounted) setState(() => _error = '检查失败：$error');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _executeUpdate() async {
    setState(() {
      _updating = true;
      _error = null;
    });
    try {
      await widget.pluginApi
          .updatePlugin(
            widget.plugin.id,
            githubProxy: _proxy.isEmpty ? null : _proxy,
          )
          .timeout(const Duration(seconds: 120));
      if (!mounted) return;
      widget.onUpdateComplete();
      Navigator.pop(context);
      ResponsiveSnackBar.showSuccess(context, message: '插件更新成功');
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = '更新失败：${error.message}');
    } on TimeoutException {
      if (mounted) setState(() => _error = '更新超时，请稍后重试');
    } catch (error) {
      if (mounted) setState(() => _error = '更新失败：$error');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }
}

class _JSPluginBatchUpdateDialog extends StatefulWidget {
  final JSPluginApi pluginApi;
  final VoidCallback onUpdateComplete;

  const _JSPluginBatchUpdateDialog({
    required this.pluginApi,
    required this.onUpdateComplete,
  });

  @override
  State<_JSPluginBatchUpdateDialog> createState() =>
      _JSPluginBatchUpdateDialogState();
}

class _JSPluginBatchUpdateDialogState
    extends State<_JSPluginBatchUpdateDialog> {
  int _proxyIndex = 0;
  final _customProxyController = TextEditingController();
  bool _updating = false;
  String? _error;
  JSPluginBatchUpdateResponse? _result;

  String get _proxy => _proxyIndex == -1
      ? _customProxyController.text.trim()
      : _kGithubProxies[_proxyIndex].value;

  @override
  void dispose() {
    _customProxyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.system_update_alt_rounded),
          SizedBox(width: 9),
          Text('更新全部插件'),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: context.responsiveDialogMaxWidth,
          maxHeight: MediaQuery.sizeOf(context).height * 0.65,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_updating && _result == null) ...[
                const Text('将依次检查所有支持远程更新的插件，并安装可用的新版本。'),
                const SizedBox(height: 14),
                _ProxySelector(
                  selectedIndex: _proxyIndex,
                  customController: _customProxyController,
                  onChanged: (value) => setState(() => _proxyIndex = value),
                ),
              ],
              if (_error != null)
                _MessagePanel(
                  icon: Icons.error_outline_rounded,
                  message: _error!,
                  color: colorScheme.error,
                ),
              if (_updating)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 14),
                      Text('正在检查并更新全部插件…'),
                    ],
                  ),
                )
              else if (_result != null)
                _BatchUpdateResult(result: _result!),
            ],
          ),
        ),
      ),
      actions: [
        if (!_updating && _result == null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        if (!_updating && _result == null)
          FilledButton(onPressed: _execute, child: const Text('开始更新')),
        if (_result != null)
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
      ],
    );
  }

  Future<void> _execute() async {
    setState(() {
      _updating = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await widget.pluginApi
          .updateAllPlugins(githubProxy: _proxy.isEmpty ? null : _proxy)
          .timeout(const Duration(seconds: 300));
      if (mounted) {
        setState(() => _result = result);
        widget.onUpdateComplete();
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = '批量更新失败：${error.message}');
    } on TimeoutException {
      if (mounted) setState(() => _error = '批量更新超时，请稍后重试');
    } catch (error) {
      if (mounted) setState(() => _error = '批量更新失败：$error');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }
}

class _ProxyConfirmDialog extends StatefulWidget {
  final String title;
  final String description;
  final String confirmLabel;

  const _ProxyConfirmDialog({
    required this.title,
    required this.description,
    required this.confirmLabel,
  });

  @override
  State<_ProxyConfirmDialog> createState() => _ProxyConfirmDialogState();
}

class _ProxyConfirmDialogState extends State<_ProxyConfirmDialog> {
  int _proxyIndex = 0;
  final _customProxyController = TextEditingController();

  String get _proxy => _proxyIndex == -1
      ? _customProxyController.text.trim()
      : _kGithubProxies[_proxyIndex].value;

  @override
  void dispose() {
    _customProxyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.responsiveDialogMaxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.description),
            const SizedBox(height: 14),
            _ProxySelector(
              selectedIndex: _proxyIndex,
              customController: _customProxyController,
              onChanged: (value) => setState(() => _proxyIndex = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _proxy),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _ProxySelector extends StatelessWidget {
  final int selectedIndex;
  final TextEditingController customController;
  final ValueChanged<int> onChanged;

  const _ProxySelector({
    required this.selectedIndex,
    required this.customController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          initialValue: selectedIndex,
          decoration: const InputDecoration(
            labelText: 'GitHub 下载方式',
            prefixIcon: Icon(Icons.route_rounded),
          ),
          items: [
            for (var index = 0; index < _kGithubProxies.length; index++)
              DropdownMenuItem(
                value: index,
                child: Text(_kGithubProxies[index].label),
              ),
            const DropdownMenuItem(value: -1, child: Text('自定义代理地址')),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
        if (selectedIndex == -1) ...[
          const SizedBox(height: 10),
          TextField(
            controller: customController,
            decoration: const InputDecoration(
              labelText: '自定义代理地址',
              hintText: 'https://your-proxy.example/',
              helperText: '请输入完整地址，并以 / 结尾',
            ),
          ),
        ],
      ],
    );
  }
}

class _BatchUpdateResult extends StatelessWidget {
  final JSPluginBatchUpdateResponse result;

  const _BatchUpdateResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ResultStat(label: '已更新', count: result.updated, color: Colors.green),
            _ResultStat(
              label: '失败',
              count: result.failed,
              color: colorScheme.error,
            ),
            _ResultStat(
              label: '无需更新',
              count: result.skipped,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final item in result.results)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              item.success
                  ? Icons.check_circle_rounded
                  : item.error != null
                      ? Icons.error_outline_rounded
                      : Icons.check_rounded,
              color: item.success
                  ? Colors.green
                  : item.error != null
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
            ),
            title: Text(
              item.pluginName.isEmpty ? item.entryPath : item.pluginName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              item.success
                  ? 'v${item.currentVersion} → v${item.newVersion}'
                  : item.error ?? 'v${item.currentVersion} 已是最新',
            ),
          ),
      ],
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _ResultStat({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _MessagePanel({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 9),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _PluginLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PluginLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: colorScheme.error, size: 34),
          const SizedBox(height: 9),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重新加载'),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlugins extends StatelessWidget {
  const _EmptyPlugins();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.extension_off_rounded,
            size: 44,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            '还没有安装插件',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '可以从上方上传插件包，或进入插件商店安装',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPluginResults extends StatelessWidget {
  const _NoPluginResults();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            const Text('没有找到符合条件的插件'),
          ],
        ),
      ),
    );
  }
}
