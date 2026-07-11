from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = root / "lib/features/auth/presentation/login_page.dart"
text = path.read_text(encoding="utf-8")


def replace_once(old: str, new: str, label: str) -> None:
    global text
    if old not in text:
        raise RuntimeError(f"missing patch anchor: {label}")
    text = text.replace(old, new, 1)


if "Future<void> _openTvAssistedInput()" in text:
    print("TV assisted input already connected")
    raise SystemExit(0)

replace_once(
    "import 'providers/auth_provider.dart';\n",
    "import 'providers/auth_provider.dart';\n"
    "import 'tv_assisted_input_dialog.dart';\n",
    "assisted input import",
)

replace_once(
    "  final _loginButtonFocusNode = FocusNode();\n",
    "  final _loginButtonFocusNode = FocusNode();\n"
    "  final _assistInputFocusNode = FocusNode();\n",
    "assist focus node",
)

replace_once(
    "    _loginButtonFocusNode.dispose();\n",
    "    _loginButtonFocusNode.dispose();\n"
    "    _assistInputFocusNode.dispose();\n",
    "assist focus dispose",
)

method_anchor = "  Future<void> _handleLogin() async {\n"
method = '''  Future<void> _openTvAssistedInput() async {
    final credentials = await showTvAssistedInputDialog(context);
    if (!mounted || credentials == null) return;

    setState(() {
      _useManualApiUrl = true;
      _apiUrlController.text = credentials.apiUrl;
      _usernameController.text = credentials.username;
      _passwordController.text = credentials.password;
      _currentStep = _totalSteps;
    });

    await Future<void>.delayed(Duration.zero);
    if (mounted) await _handleLogin();
  }

'''
replace_once(method_anchor, method + method_anchor, "assisted input method")

username_block = '''                            // 用户名
                            _buildTvInputField(
                              context: context,
                              controller: _usernameController,
                              focusNode: _usernameFocusNode,
                              nextFocusNode: _passwordFocusNode,
                              previousFocusNode: null,
                              colorScheme: colorScheme,
                              labelText: '用户名',
                              hintText: '请输入用户名',
                              prefixIcon: Icons.person_outline,
                              autofocus: true,
'''
username_new = '''                            // 手机辅助输入（推荐）
                            _buildTvAssistedInputButton(
                              context,
                              colorScheme,
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Text(
                                    '或使用遥控器手动输入',
                                    style: TvTheme.captionStyle(context),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // 用户名
                            _buildTvInputField(
                              context: context,
                              controller: _usernameController,
                              focusNode: _usernameFocusNode,
                              nextFocusNode: _passwordFocusNode,
                              previousFocusNode: _assistInputFocusNode,
                              colorScheme: colorScheme,
                              labelText: '用户名',
                              hintText: '请输入用户名',
                              prefixIcon: Icons.person_outline,
                              autofocus: false,
'''
replace_once(username_block, username_new, "TV username and assist button")

helper_anchor = "  /// TV 通用输入框\n"
helper = '''  Widget _buildTvAssistedInputButton(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return TvFocusable(
      focusNode: _assistInputFocusNode,
      autofocus: true,
      onSelect: _openTvAssistedInput,
      onFocusChange: (hasFocus) {
        if (hasFocus) _setCurrentStep(1);
      },
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _usernameFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      focusedScale: 1.025,
      borderRadius: 18,
      child: ExcludeFocus(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.tertiaryContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 30,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '手机辅助输入',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '推荐',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '用手机扫描二维码填写服务器、账号和密码',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 30,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

'''
replace_once(helper_anchor, helper + helper_anchor, "assisted input button helper")

path.write_text(text, encoding="utf-8")
print("TV assisted input connected to login page")
