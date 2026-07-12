import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/server_connection_provider.dart';
import '../../features/library/presentation/providers/songs_provider.dart';
import '../../features/playlist/presentation/providers/playlist_provider.dart';
import '../widgets/server_connection_banner.dart';

/// 在主导航内容上方显示连接状态，并在连接恢复后刷新核心数据。
class ServerConnectionHost extends ConsumerWidget {
  final Widget child;

  const ServerConnectionHost({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<ServerConnectionState>(serverConnectionProvider, (
      previous,
      next,
    ) {
      final recovered =
          next.isConnected &&
          next.recoveryGeneration != (previous?.recoveryGeneration ?? 0);
      if (!recovered) return;

      ref.invalidate(playlistListProvider(null));
      ref.invalidate(playlistListProvider('normal'));
      ref.invalidate(playlistListProvider('radio'));
      unawaited(ref.read(songsListProvider.notifier).refresh());
    });

    return Column(
      children: [
        const ServerConnectionBanner(),
        Expanded(child: child),
      ],
    );
  }
}
