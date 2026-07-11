import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/tv_theme.dart';
import '../../../shared/widgets/tv_focusable.dart';
import 'tv_assisted_input_service.dart';

Future<TvAssistedCredentials?> showTvAssistedInputDialog(
  BuildContext context,
) {
  return showDialog<TvAssistedCredentials>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _TvAssistedInputDialog(),
  );
}

class _TvAssistedInputDialog extends StatefulWidget {
  const _TvAssistedInputDialog();

  @override
  State<_TvAssistedInputDialog> createState() =>
      _TvAssistedInputDialogState();
}

class _TvAssistedInputDialogState extends State<_TvAssistedInputDialog> {
  TvAssistedInputService? _service;
  TvAssistedCredentials? _received;
  StreamSubscription<TvAssistedCredentials>? _subscription;
  Timer? _countdownTimer;
  String? _error;
  int _remainingSeconds = 0;
  bool _starting = true;

  @override
  void initState() {
    super.initState();
    _startService();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _subscription?.cancel();
    unawaited(_service?.close());
    super.dispose();
  }

  Future<void> _startService() async {
    _countdownTimer?.cancel();
    await _subscription?.cancel();
    await _service?.close();
    if (mounted) {
      setState(() {
        _starting = true;
        _error = null;
        _received = null;
      });
    }

    try {
      final service = await TvAssistedInputService.start();
      if (!mounted) {
        await service.close();
        return;
      }
      _service = service;
      _remainingSeconds = service.expiresAt
          .difference(DateTime.now())
          .inSeconds
          .clamp(0, 300);
      _subscription = service.credentials.listen((credentials) {
        if (!mounted) return;
        setState(() => _received = credentials);
      });
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _service == null) return;
        final remaining = _service!.expiresAt
            .difference(DateTime.now())
            .inSeconds
            .clamp(0, 300);
        setState(() => _remainingSeconds = remaining);
        if (remaining == 0) _countdownTimer?.cancel();
      });
      setState(() => _starting = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = '无法启动手机辅助输入：$error';
      });
    }
  }

  String get _countdownLabel {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 64, vertical: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, minHeight: 540),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: _starting
              ? _buildLoading(theme)
              : _error != null
                  ? _buildError(theme, colorScheme)
                  : _received != null
                      ? _buildConfirmation(theme, colorScheme, _received!)
                      : _buildWaiting(theme, colorScheme),
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 22),
          Text('正在启动手机辅助输入…', style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 72, color: colorScheme.error),
          const SizedBox(height: 20),
          Text(
            '手机辅助输入不可用',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TvDialogButton(
                autofocus: true,
                icon: Icons.refresh_rounded,
                label: '重新尝试',
                onPressed: _startService,
              ),
              const SizedBox(width: 16),
              _TvDialogButton(
                icon: Icons.close_rounded,
                label: '关闭',
                filled: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaiting(ThemeData theme, ColorScheme colorScheme) {
    final service = _service!;
    final expired = _remainingSeconds <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                Icons.phone_android_rounded,
                color: colorScheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '用手机填写登录信息',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '手机和电视需要连接同一个局域网',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: expired
                    ? colorScheme.errorContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                expired ? '已过期' : '剩余 $_countdownLabel',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: expired
                      ? colorScheme.onErrorContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: expired
                      ? Center(
                          child: Icon(
                            Icons.timer_off_rounded,
                            size: 100,
                            color: Colors.grey.shade500,
                          ),
                        )
                      : Center(
                          child: QrImageView(
                            data: service.qrUrl,
                            version: QrVersions.auto,
                            size: 300,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StepCard(
                      index: '1',
                      title: '扫描二维码',
                      description: '使用手机相机或浏览器扫描左侧二维码。',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 14),
                    _StepCard(
                      index: '2',
                      title: '填写登录信息',
                      description: '在手机上输入服务器地址、用户名和密码。',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 14),
                    _StepCard(
                      index: '3',
                      title: '回到电视确认',
                      description: '电视收到信息后仍会要求确认，不会直接登录。',
                      colorScheme: colorScheme,
                    ),
                    const Spacer(),
                    Text(
                      '无法扫码？在手机浏览器中打开',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      service.manualUrl,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '配对码',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${service.pairCode.substring(0, 3)} ${service.pairCode.substring(3)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (expired)
              _TvDialogButton(
                autofocus: true,
                icon: Icons.refresh_rounded,
                label: '重新生成',
                onPressed: _startService,
              ),
            if (expired) const SizedBox(width: 16),
            _TvDialogButton(
              autofocus: !expired,
              icon: Icons.close_rounded,
              label: '取消',
              filled: false,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmation(
    ThemeData theme,
    ColorScheme colorScheme,
    TvAssistedCredentials credentials,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.mobile_friendly_rounded,
                size: 34,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '手机已发送登录信息',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '请确认服务器和账号无误后登录',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 34),
        _CredentialRow(
          icon: Icons.cloud_outlined,
          label: '服务器',
          value: credentials.apiUrl,
        ),
        const SizedBox(height: 16),
        _CredentialRow(
          icon: Icons.person_outline_rounded,
          label: '用户名',
          value: credentials.username,
        ),
        const SizedBox(height: 16),
        const _CredentialRow(
          icon: Icons.lock_outline_rounded,
          label: '密码',
          value: '••••••••',
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '登录信息仅保存在电视内存中；确认后使用现有 Songloft 登录接口。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _TvDialogButton(
              icon: Icons.refresh_rounded,
              label: '重新填写',
              filled: false,
              onPressed: () {
                _service?.allowAnotherSubmission();
                setState(() => _received = null);
              },
            ),
            const SizedBox(width: 16),
            _TvDialogButton(
              autofocus: true,
              icon: Icons.login_rounded,
              label: '确认并登录',
              onPressed: () => Navigator.of(context).pop(credentials),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.title,
    required this.description,
    required this.colorScheme,
  });

  final String index;
  final String title;
  final String description;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              index,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 28),
          const SizedBox(width: 16),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TvDialogButton extends StatelessWidget {
  const _TvDialogButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.autofocus = false,
    this.filled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool autofocus;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final button = filled
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          );

    return TvFocusable(
      autofocus: autofocus,
      onSelect: onPressed,
      focusedScale: 1.04,
      borderRadius: 14,
      child: ExcludeFocus(
        child: SizedBox(
          height: TvTheme.minButtonSize,
          child: button,
        ),
      ),
    );
  }
}
