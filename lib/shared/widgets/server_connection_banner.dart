import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/server_connection_provider.dart';
import '../../core/theme/accessibility.dart';

class ServerConnectionBanner extends ConsumerWidget {
  const ServerConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serverConnectionProvider);
    final shouldShow =
        state.phase != ServerConnectionPhase.connected ||
        state.showRestoredMessage;
    final duration = AppAccessibility.motionDuration(
      context,
      const Duration(milliseconds: 180),
    );

    return AnimatedSize(
      duration: duration,
      alignment: Alignment.topCenter,
      child:
          shouldShow
              ? _ConnectionBannerContent(
                state: state,
                onRetry:
                    () =>
                        ref.read(serverConnectionProvider.notifier).retryNow(),
              )
              : const SizedBox.shrink(),
    );
  }
}

class _ConnectionBannerContent extends StatelessWidget {
  final ServerConnectionState state;
  final VoidCallback onRetry;

  const _ConnectionBannerContent({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final restored =
        state.phase == ServerConnectionPhase.connected &&
        state.showRestoredMessage;
    final reconnecting = state.phase == ServerConnectionPhase.reconnecting;
    final background =
        restored ? colorScheme.primaryContainer : colorScheme.errorContainer;
    final foreground =
        restored
            ? colorScheme.onPrimaryContainer
            : colorScheme.onErrorContainer;
    final title =
        restored
            ? '连接已恢复'
            : reconnecting
            ? '正在重新连接服务器…'
            : '无法连接服务器';
    final subtitle =
        restored
            ? '首页、歌曲库和歌单正在自动刷新'
            : reconnecting
            ? '正在检查服务器是否恢复可用'
            : state.lastError ?? '请检查网络、服务器地址或 NAS 状态';

    return Semantics(
      container: true,
      liveRegion: true,
      label: '$title，$subtitle',
      child: Material(
        color: background,
        child: SafeArea(
          bottom: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
              child: Row(
                children: [
                  if (reconnecting)
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: foreground,
                      ),
                    )
                  else
                    Icon(
                      restored
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      color: foreground,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground.withValues(alpha: 0.82),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!restored)
                    TextButton(
                      onPressed: reconnecting ? null : onRetry,
                      style: TextButton.styleFrom(
                        foregroundColor: foreground,
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Text('立即重试'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
