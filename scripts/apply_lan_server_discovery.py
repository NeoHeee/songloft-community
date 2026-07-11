from pathlib import Path
import re


path = Path('lib/features/auth/presentation/login_page.dart')
text = path.read_text(encoding='utf-8')

text = text.replace(
    "import '../../../core/network/base_url_provider.dart';\n",
    "import '../../../core/network/base_url_provider.dart';\n"
    "import '../../../core/network/server_discovery.dart';\n",
    1,
)

text = text.replace(
    "  bool _isLocalModeBootstrapping = false;\n"
    "  String _localModeHint = '';\n",
    "  bool _isLocalModeBootstrapping = false;\n"
    "  String _localModeHint = '';\n\n"
    "  bool _isDiscoveringServers = false;\n"
    "  bool _cancelServerDiscovery = false;\n"
    "  int _discoveryChecked = 0;\n"
    "  int _discoveryTotal = 0;\n"
    "  int _discoveryFoundCount = 0;\n"
    "  String _discoveryNetwork = '';\n"
    "  String? _discoveryMessage;\n"
    "  List<DiscoveredServer> _discoveredServers =\n"
    "      const <DiscoveredServer>[];\n",
    1,
)

method_marker = "  @override\n  void dispose() {\n"
methods = r'''  Future<void> _discoverLanServers() async {
    if (kIsWeb) {
      ResponsiveSnackBar.show(
        context,
        message: '浏览器受安全策略限制，无法自动扫描局域网，请手动输入 API 地址',
      );
      return;
    }
    if (_isDiscoveringServers) return;

    final savedServers =
        ref.read(serversProvider).value ?? const <ServerEntry>[];
    final ports = <int>{58091};
    for (final entry in savedServers) {
      final uri = Uri.tryParse(entry.url);
      if (uri != null && uri.hasPort) ports.add(uri.port);
    }

    var lastReportedFound = -1;
    setState(() {
      _isDiscoveringServers = true;
      _cancelServerDiscovery = false;
      _discoveryChecked = 0;
      _discoveryTotal = 0;
      _discoveryFoundCount = 0;
      _discoveryNetwork = '';
      _discoveryMessage = '正在查找当前局域网中的 Songloft 服务器…';
      _discoveredServers = const <DiscoveredServer>[];
    });

    try {
      final results = await discoverSongloftServers(
        ports: ports,
        timeout: const Duration(milliseconds: 700),
        concurrency: 28,
        isCancelled: () => _cancelServerDiscovery,
        onProgress: (progress) {
          if (!mounted) return;
          final shouldUpdate =
              progress.checked == progress.total ||
              progress.checked % 4 == 0 ||
              progress.found != lastReportedFound;
          if (!shouldUpdate) return;
          lastReportedFound = progress.found;
          setState(() {
            _discoveryChecked = progress.checked;
            _discoveryTotal = progress.total;
            _discoveryFoundCount = progress.found;
            _discoveryNetwork = progress.network;
          });
        },
      );
      if (!mounted) return;

      final wasCancelled = _cancelServerDiscovery;
      setState(() {
        _isDiscoveringServers = false;
        _cancelServerDiscovery = false;
        _discoveredServers = results;
        _discoveryFoundCount = results.length;
        _discoveryMessage =
            wasCancelled
                ? '已停止搜索，保留当前发现结果'
                : results.isEmpty
                ? '未发现 Songloft 服务器。请确认设备处于同一局域网，且未开启 AP 隔离。'
                : '发现 ${results.length} 个可用服务器';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isDiscoveringServers = false;
        _cancelServerDiscovery = false;
        _discoveryMessage = '搜索失败：$error';
      });
    }
  }

  void _stopServerDiscovery() {
    if (!_isDiscoveringServers) return;
    setState(() {
      _cancelServerDiscovery = true;
      _discoveryMessage = '正在停止搜索…';
    });
  }

  Future<void> _useDiscoveredServer(DiscoveredServer server) async {
    final savedServers =
        ref.read(serversProvider).value ?? const <ServerEntry>[];
    if (!savedServers.any((entry) => entry.url == server.url)) {
      await ref
          .read(serversProvider.notifier)
          .add(
            ServerEntry(
              id: ServerEntry.generateId(),
              name: '局域网 ${server.host}',
              url: server.url,
            ),
          );
    }
    if (!mounted) return;

    ref.read(baseUrlProvider.notifier).set(server.url);
    _apiUrlController.text = server.url;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _discoveryMessage = '已选择 ${server.url}');
    ResponsiveSnackBar.showSuccess(
      context,
      message: '已选择服务器 ${server.url}',
    );
  }

'''
if methods.strip() not in text:
    text = text.replace(method_marker, methods + method_marker, 1)

text = text.replace(
    "  void dispose() {\n"
    "    _usernameFocusNode.removeListener(_updateStep);\n",
    "  void dispose() {\n"
    "    _cancelServerDiscovery = true;\n"
    "    _usernameFocusNode.removeListener(_updateStep);\n",
    1,
)

old_api_start = text.index('  Widget _buildApiUrlField(ColorScheme colorScheme) {')
old_api_end = text.index('  Widget _buildLoginButton(', old_api_start)
new_api = r'''  Widget _buildApiUrlField(ColorScheme colorScheme) {
    final servers = ref.watch(serversProvider).value ?? const <ServerEntry>[];
    final Widget serverField;
    if (servers.length >= 2) {
      final current = ref.watch(baseUrlProvider);
      final selected =
          servers.any((server) => server.url == current)
              ? current
              : servers.first.url;
      serverField = DropdownButtonFormField<String>(
        initialValue: selected,
        decoration: const InputDecoration(
          labelText: '服务器',
          prefixIcon: Icon(Icons.cloud_outlined),
        ),
        items:
            servers
                .map(
                  (server) => DropdownMenuItem(
                    value: server.url,
                    child: Text(
                      server.name.isNotEmpty
                          ? '${server.name} (${server.url})'
                          : server.url,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
        onChanged: (url) {
          if (url != null) ref.read(baseUrlProvider.notifier).set(url);
        },
      );
    } else {
      serverField = TextFormField(
        controller: _apiUrlController,
        focusNode: _apiUrlFocusNode,
        decoration: InputDecoration(
          labelText: 'API 地址',
          hintText: AppConfig.baseUrl,
          prefixIcon: const Icon(Icons.cloud_outlined),
        ),
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.done,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '请输入 API 地址';
          }
          if (!value.startsWith('http://') &&
              !value.startsWith('https://')) {
            return '请输入有效的 URL（以 http:// 或 https:// 开头）';
          }
          return null;
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        serverField,
        const SizedBox(height: 10),
        _buildServerDiscoveryControls(colorScheme),
      ],
    );
  }

  Widget _buildServerDiscoveryControls(ColorScheme colorScheme) {
    if (kIsWeb) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.radar_rounded),
            label: const Text('浏览器不支持局域网自动搜索'),
          ),
          const SizedBox(height: 6),
          Text(
            '请手动输入 API 地址；Android、Windows 和 TV 客户端可自动搜索。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final progress =
        _discoveryTotal <= 0
            ? null
            : (_discoveryChecked / _discoveryTotal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed:
              _isDiscoveringServers
                  ? _stopServerDiscovery
                  : _discoverLanServers,
          icon:
              _isDiscoveringServers
                  ? const Icon(Icons.stop_circle_outlined)
                  : const Icon(Icons.radar_rounded),
          label: Text(
            _isDiscoveringServers ? '停止搜索' : '自动搜索局域网服务器',
          ),
        ),
        if (_isDiscoveringServers) ...[
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 6),
          Text(
            _discoveryTotal > 0
                ? '$_discoveryNetwork · 已检查 $_discoveryChecked / $_discoveryTotal · 发现 $_discoveryFoundCount 个'
                : '正在识别本机网络…',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (_discoveryMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _discoveryMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:
                  _discoveredServers.isEmpty
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.primary,
            ),
          ),
        ],
        if (_discoveredServers.isNotEmpty) ...[
          const SizedBox(height: 8),
          ..._discoveredServers.take(8).map(
            (server) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.dns_rounded, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            server.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${server.network} · ${server.latencyLabel}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () => _useDiscoveredServer(server),
                      child: const Text('使用'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

'''
text = text[:old_api_start] + new_api + text[old_api_end:]

api_tv_pattern = re.compile(
    r"(\s+_buildTvInputField\(\n"
    r"\s+context: context,\n"
    r"\s+controller: _apiUrlController,.*?\n"
    r"\s+\),\n)"
    r"(\s+const SizedBox\(height: TvTheme\.spacingLarge\),)",
    re.S,
)
text, count = api_tv_pattern.subn(
    r"\1                              const SizedBox(height: 10),\n"
    r"                              _buildServerDiscoveryControls(colorScheme),\n"
    r"\2",
    text,
    count=1,
)
if count != 1:
    raise RuntimeError(f'Unable to insert TV discovery controls: {count}')

path.write_text(text, encoding='utf-8')
print('Applied LAN server discovery to login page')
