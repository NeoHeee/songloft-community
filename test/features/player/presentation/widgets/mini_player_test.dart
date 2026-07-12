import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songloft_flutter/features/player/domain/player_state.dart';
import 'package:songloft_flutter/features/player/presentation/providers/player_provider.dart';
import 'package:songloft_flutter/features/player/presentation/widgets/mini_player.dart';
import 'package:songloft_flutter/shared/models/song.dart';

final testSong = Song(
  id: 1,
  type: 'local',
  title: '测试歌曲',
  artist: '测试歌手',
  duration: 180,
  addedAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

class FakePlayerNotifier extends PlayerNotifier {
  var retryCount = 0;

  @override
  PlayerState build() => PlayerState(
    currentSong: testSong,
    playlist: [testSong],
    currentIndex: 0,
    errorMessage: '播放失败',
  );

  @override
  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }

  @override
  Future<void> togglePlay() async {
    retryCount++;
    state = state.copyWith(isPlaying: true, isRetrying: false);
  }
}

void main() {
  testWidgets('播放失败时显示重试按钮并触发重新播放', (tester) async {
    final notifier = FakePlayerNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [playerStateProvider.overrideWith(() => notifier)],
        child: const MaterialApp(home: Scaffold(body: MiniPlayer())),
      ),
    );

    expect(find.text('播放失败'), findsOneWidget);
    expect(find.byTooltip('重试播放'), findsOneWidget);
    await tester.tap(find.byTooltip('重试播放'));
    await tester.pump();
    expect(notifier.retryCount, 1);
  });
}
