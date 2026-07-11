from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / "lib/features/auth/presentation/login_page.dart"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f"missing patch anchor: {label}")
    return text.replace(old, new, 1)


def main() -> None:
    text = PATH.read_text(encoding="utf-8")
    if "Widget _buildTvServerSection(" in text:
        print("TV login round already applied")
        return

    text = replace_once(
        text,
        "import '../../../shared/utils/responsive_snackbar.dart';\n",
        "import '../../../shared/utils/responsive_snackbar.dart';\n"
        "import '../../../shared/widgets/tv_focusable.dart';\n",
        "TvFocusable import",
    )

    text = replace_once(
        text,
        "  final _loginButtonFocusNode = FocusNode();\n",
        "  final _loginButtonFocusNode = FocusNode();\n"
        "  final Map<String, FocusNode> _serverFocusNodes = {};\n",
        "server focus fields",
    )
    text = replace_once(
        text,
        "  bool _obscurePassword = true;\n",
        "  bool _obscurePassword = true;\n"
        "  bool _useManualApiUrl = false;\n",
        "manual API state",
    )
    text = replace_once(
        text,
        "  int _currentStep = 1;\n"
        "  int get _totalSteps => !AppConfig.isEmbedded ? 3 : 2;\n",
        "  int _currentStep = 1;\n"
        "  int get _totalSteps => _isApiUrlVisible ? 4 : 3;\n",
        "step count",
    )

    text = replace_once(
        text,
        "    _apiUrlFocusNode.addListener(_updateStep);\n",
        "    _apiUrlFocusNode.addListener(_updateStep);\n"
        "    _loginButtonFocusNode.addListener(_updateStep);\n",
        "login focus listener",
    )

    old_update_step = '''  void _updateStep() {
    int newStep = _currentStep;
    if (_usernameFocusNode.hasFocus) {
      newStep = 1;
    } else if (_passwordFocusNode.hasFocus) {
      newStep = 2;
    } else if (_apiUrlFocusNode.hasFocus) {
      newStep = 3;
    }
    if (newStep != _currentStep) {
      setState(() {
        _currentStep = newStep;
      });
    }
  }
'''
    new_update_step = '''  void _updateStep() {
    int newStep = _currentStep;
    if (_usernameFocusNode.hasFocus) {
      newStep = 1;
    } else if (_passwordFocusNode.hasFocus) {
      newStep = 2;
    } else if (_apiUrlFocusNode.hasFocus ||
        _serverFocusNodes.values.any((node) => node.hasFocus)) {
      newStep = 3;
    } else if (_loginButtonFocusNode.hasFocus) {
      newStep = _totalSteps;
    }
    if (newStep != _currentStep && mounted) {
      setState(() => _currentStep = newStep);
    }
  }

  void _setCurrentStep(int step) {
    if (_currentStep == step || !mounted) return;
    setState(() => _currentStep = step);
  }

  FocusNode _serverFocusNode(String id) {
    return _serverFocusNodes.putIfAbsent(id, FocusNode.new);
  }

  FocusNode? _firstServerFocusNode(List<ServerEntry> servers) {
    if (servers.isEmpty) return null;
    return _serverFocusNode(servers.first.id);
  }

  void _selectTvServer(ServerEntry entry) {
    ref.read(baseUrlProvider.notifier).set(entry.url);
    _apiUrlController.text = entry.url;
    if (entry.username != null && entry.username!.isNotEmpty) {
      _usernameController.text = entry.username!;
    }
    if (entry.password != null && entry.password!.isNotEmpty) {
      _passwordController.text = entry.password!;
    }
    setState(() {
      _useManualApiUrl = false;
      _currentStep = 3;
    });
  }

  void _showManualApiInput() {
    _apiUrlController.text = ref.read(baseUrlProvider);
    setState(() {
      _useManualApiUrl = true;
      _currentStep = 3;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _apiUrlFocusNode.requestFocus();
    });
  }
'''
    text = replace_once(text, old_update_step, new_update_step, "step logic")

    text = replace_once(
        text,
        "    _apiUrlFocusNode.removeListener(_updateStep);\n",
        "    _apiUrlFocusNode.removeListener(_updateStep);\n"
        "    _loginButtonFocusNode.removeListener(_updateStep);\n",
        "remove login listener",
    )
    text = replace_once(
        text,
        "    _loginButtonFocusNode.dispose();\n"
        "    super.dispose();\n",
        "    _loginButtonFocusNode.dispose();\n"
        "    for (final node in _serverFocusNodes.values) {\n"
        "      node.dispose();\n"
        "    }\n"
        "    super.dispose();\n",
        "dispose server nodes",
    )

    old_login_url = '''    String? apiBaseUrl;
    if (!AppConfig.isEmbedded) {
      final servers = ref.read(serversProvider).value ?? const <ServerEntry>[];
      if (servers.length >= 2) {
        // 多服务器：默认布局走 dropdown，TV 布局也以 baseUrlProvider 为准
        apiBaseUrl = ref.read(baseUrlProvider);
      } else {
        // 0/1 项：使用单输入框的值
        final raw = _apiUrlController.text.trim();
        if (raw.isNotEmpty) {
          apiBaseUrl = raw.replaceAll(RegExp(r'/+$'), '');
        }
      }
    }
'''
    new_login_url = '''    String? apiBaseUrl;
    if (!AppConfig.isEmbedded) {
      final servers = ref.read(serversProvider).value ?? const <ServerEntry>[];
      if (servers.length >= 2 && !_useManualApiUrl) {
        apiBaseUrl = ref.read(baseUrlProvider);
      } else {
        final raw = _apiUrlController.text.trim();
        if (raw.isNotEmpty) {
          apiBaseUrl = raw.replaceAll(RegExp(r'/+$'), '');
        }
      }
    }
'''
    text = replace_once(text, old_login_url, new_login_url, "login server choice")

    text = replace_once(
        text,
        "  /// 判断是否为 TV 端（屏幕宽度 >= 1920）\n"
        "  bool _isTv(BuildContext context) {\n"
        "    return MediaQuery.of(context).size.width >= 1920;\n"
        "  }\n",
        "  /// TV 模式由平台检测统一决定，避免 720p/4K 逻辑分辨率误判。\n"
        "  bool _isTv(BuildContext context) => AppConfig.isTvMode;\n",
        "unified TV detection",
    )

    text = replace_once(
        text,
        "  ) {\n"
        "    return Scaffold(\n"
        "      body: SafeArea(\n"
        "        child: FocusTraversalGroup(\n",
        "  ) {\n"
        "    final servers =\n"
        "        ref.watch(serversProvider).value ?? const <ServerEntry>[];\n"
        "    return Scaffold(\n"
        "      body: SafeArea(\n"
        "        child: FocusTraversalGroup(\n",
        "TV layout servers",
    )

    text = replace_once(
        text,
        "                            _buildTvPasswordField(context, colorScheme),\n",
        "                            _buildTvPasswordField(\n"
        "                              context,\n"
        "                              colorScheme,\n"
        "                              servers,\n"
        "                            ),\n",
        "password server routing",
    )

    old_api_block = '''                            // API 地址 — 嵌入模式下隐藏
                            if (_isApiUrlVisible) ...[
                              _buildTvInputField(
                                context: context,
                                controller: _apiUrlController,
                                focusNode: _apiUrlFocusNode,
                                nextFocusNode: _loginButtonFocusNode,
                                previousFocusNode: _passwordFocusNode,
                                colorScheme: colorScheme,
                                labelText: 'API 地址',
                                hintText: AppConfig.baseUrl,
                                prefixIcon: Icons.cloud_outlined,
                                keyboardType: TextInputType.url,
                                isLastField: true,
                                onSubmit: _handleLogin,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    if (!value.startsWith('http://') &&
                                        !value.startsWith('https://')) {
                                      return '请输入有效的 URL（以 http:// 或 https:// 开头）';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: TvTheme.spacingLarge),
                            ],
'''
    new_api_block = '''                            // 服务器选择 / API 地址 — 嵌入模式下隐藏
                            if (_isApiUrlVisible) ...[
                              _buildTvServerSection(
                                context,
                                colorScheme,
                                servers,
                              ),
                              const SizedBox(height: TvTheme.spacingLarge),
                            ],
'''
    text = replace_once(text, old_api_block, new_api_block, "TV server section")

    text = replace_once(
        text,
        "        Text(\n"
        "          '自托管本地音乐服务',\n"
        "          style: theme.textTheme.titleLarge?.copyWith(\n"
        "            color: colorScheme.onSurfaceVariant,\n"
        "            fontSize: TvTheme.fontSizeBody,\n"
        "          ),\n"
        "        ),\n",
        "        Text(\n"
        "          '自托管本地音乐服务',\n"
        "          style: theme.textTheme.titleLarge?.copyWith(\n"
        "            color: colorScheme.onSurfaceVariant,\n"
        "            fontSize: TvTheme.fontSizeBody,\n"
        "          ),\n"
        "        ),\n"
        "        const SizedBox(height: 34),\n"
        "        Container(\n"
        "          width: 360,\n"
        "          padding: const EdgeInsets.all(20),\n"
        "          decoration: BoxDecoration(\n"
        "            color: colorScheme.surface.withValues(alpha: 0.58),\n"
        "            borderRadius: BorderRadius.circular(20),\n"
        "            border: Border.all(\n"
        "              color: colorScheme.outlineVariant.withValues(alpha: 0.45),\n"
        "            ),\n"
        "          ),\n"
        "          child: Column(\n"
        "            children: [\n"
        "              _buildTvGuideRow(\n"
        "                colorScheme,\n"
        "                Icons.gamepad_rounded,\n"
        "                '方向键移动焦点',\n"
        "              ),\n"
        "              const SizedBox(height: 12),\n"
        "              _buildTvGuideRow(\n"
        "                colorScheme,\n"
        "                Icons.keyboard_rounded,\n"
        "                '确认键打开系统键盘',\n"
        "              ),\n"
        "              const SizedBox(height: 12),\n"
        "              _buildTvGuideRow(\n"
        "                colorScheme,\n"
        "                Icons.login_rounded,\n"
        "                '完成输入后选择登录',\n"
        "              ),\n"
        "            ],\n"
        "          ),\n"
        "        ),\n",
        "TV guide card",
    )

    branding_end = "  /// TV 通用输入框\n"
    helpers = '''  Widget _buildTvGuideRow(
    ColorScheme colorScheme,
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(icon, size: 24, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: TvTheme.fontSizeCaption,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTvServerSection(
    BuildContext context,
    ColorScheme colorScheme,
    List<ServerEntry> servers,
  ) {
    if (servers.length < 2 || _useManualApiUrl) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTvInputField(
            context: context,
            controller: _apiUrlController,
            focusNode: _apiUrlFocusNode,
            nextFocusNode: _loginButtonFocusNode,
            previousFocusNode: _passwordFocusNode,
            colorScheme: colorScheme,
            labelText: 'API 地址',
            hintText: '例如：http://192.168.1.10:3000',
            prefixIcon: Icons.cloud_outlined,
            keyboardType: TextInputType.url,
            isLastField: true,
            onSubmit: _handleLogin,
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
          ),
          if (servers.length >= 2) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _useManualApiUrl = false);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _firstServerFocusNode(servers)?.requestFocus();
                  });
                },
                icon: const Icon(Icons.dns_rounded),
                label: const Text('返回已保存服务器'),
              ),
            ),
          ],
        ],
      );
    }

    final selectedUrl = ref.watch(baseUrlProvider);
    final cards = <Widget>[
      for (final server in servers)
        _buildTvServerCard(
          context,
          colorScheme,
          server: server,
          selected: server.url == selectedUrl,
        ),
      _buildTvManualServerCard(context, colorScheme),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.dns_rounded, color: colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              '选择服务器',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const Spacer(),
            Text(
              '${servers.length} 个已保存',
              style: TvTheme.captionStyle(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final card in cards) SizedBox(width: width, child: card),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTvServerCard(
    BuildContext context,
    ColorScheme colorScheme, {
    required ServerEntry server,
    required bool selected,
  }) {
    return TvFocusable(
      focusNode: _serverFocusNode(server.id),
      onFocusChange: (hasFocus) {
        if (hasFocus) _setCurrentStep(3);
      },
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _passwordFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _loginButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onSelect: () => _selectTvServer(server),
      focusedScale: 1.025,
      borderRadius: 16,
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.62)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.65)
                : colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.cloud_done_rounded : Icons.cloud_outlined,
              color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    server.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TvTheme.captionStyle(context),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTvManualServerCard(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return TvFocusable(
      focusNode: _serverFocusNode('__manual__'),
      onFocusChange: (hasFocus) {
        if (hasFocus) _setCurrentStep(3);
      },
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _passwordFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _loginButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onSelect: _showManualApiInput,
      focusedScale: 1.025,
      borderRadius: 16,
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.add_link_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '手动输入地址',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text('连接新的 Songloft 服务', style: TvTheme.captionStyle(context)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

'''
    text = replace_once(text, branding_end, helpers + branding_end, "server helpers")

    old_password_signature = '''  Widget _buildTvPasswordField(BuildContext context, ColorScheme colorScheme) {
    const bool isLast = AppConfig.isEmbedded;
    return _TvFocusableTextField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      nextFocusNode: isLast ? _loginButtonFocusNode : _apiUrlFocusNode,
'''
    new_password_signature = '''  Widget _buildTvPasswordField(
    BuildContext context,
    ColorScheme colorScheme,
    List<ServerEntry> servers,
  ) {
    const bool isLast = AppConfig.isEmbedded;
    final nextFocusNode = isLast
        ? _loginButtonFocusNode
        : (servers.length >= 2 && !_useManualApiUrl
              ? _firstServerFocusNode(servers) ?? _apiUrlFocusNode
              : _apiUrlFocusNode);
    return _TvFocusableTextField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      nextFocusNode: nextFocusNode,
'''
    text = replace_once(
        text,
        old_password_signature,
        new_password_signature,
        "password next focus",
    )

    start = text.index("  /// TV 登录按钮\n")
    end = text.index("  // ========== 共用 Widget 方法", start)
    old_login_button = text[start:end]
    new_login_button = '''  /// TV 登录按钮
  Widget _buildTvLoginButton(
    BuildContext context,
    AuthState authState,
    ColorScheme colorScheme,
  ) {
    final enabled = !authState.isLoading;
    return TvFocusable(
      focusNode: _loginButtonFocusNode,
      onFocusChange: (_) => _updateStep(),
      onSelect: enabled ? _handleLogin : null,
      enabled: enabled,
      focusedScale: 1.035,
      borderRadius: 16,
      child: ExcludeFocus(
        child: FilledButton(
          onPressed: enabled ? _handleLogin : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(TvTheme.minButtonSize),
            textStyle: TvTheme.buttonStyle(context).copyWith(
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: authState.isLoading
              ? SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Text('登录'),
        ),
      ),
    );
  }

'''
    text = text[:start] + new_login_button + text[end:]

    old_key_enter = '''    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select) {
      if (!widget.isLastField && widget.nextFocusNode != null) {
        widget.nextFocusNode!.requestFocus();
        return KeyEventResult.handled;
      } else if (widget.isLastField && widget.onFieldSubmitted != null) {
        widget.onFieldSubmitted!(widget.controller.text);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
'''
    new_key_enter = '''    }

    // 确认键交给 TextFormField，自然调用电视系统键盘；
    // 输入完成后的“下一步/完成”由 onFieldSubmitted 处理。
    return KeyEventResult.ignored;
'''
    text = replace_once(text, old_key_enter, new_key_enter, "text field confirm behavior")

    text = replace_once(
        text,
        "    return Focus(\n"
        "      focusNode: widget.focusNode,\n"
        "      onKeyEvent: _handleKeyEvent,\n",
        "    return Focus(\n"
        "      canRequestFocus: false,\n"
        "      onKeyEvent: _handleKeyEvent,\n",
        "text field focus wrapper",
    )
    text = replace_once(
        text,
        "        child: TextFormField(\n"
        "          controller: widget.controller,\n"
        "          autofocus: widget.autofocus,\n",
        "        child: TextFormField(\n"
        "          controller: widget.controller,\n"
        "          focusNode: widget.focusNode,\n"
        "          autofocus: widget.autofocus,\n",
        "text field actual focus node",
    )

    PATH.write_text(text, encoding="utf-8")
    print("TV login optimization applied")


if __name__ == "__main__":
    main()
