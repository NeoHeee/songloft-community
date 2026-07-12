import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songloft_flutter/config/constants.dart';
import 'package:songloft_flutter/features/library/presentation/widgets/song_list_tile.dart';
import 'package:songloft_flutter/shared/models/song.dart';
import 'package:songloft_flutter/shared/widgets/cover_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final song = Song(
    id: 1,
    type: AppConstants.songTypeLocal,
    title: '测试歌曲',
    artist: '测试歌手',
    duration: 180,
    addedAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Future<void> pumpMobileTile(
    WidgetTester tester, {
    bool isSelectionMode = false,
    bool isSelected = false,
    VoidCallback? onSelect,
    VoidCallback? onLongPress,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SongListTile(
              song: song,
              index: 0,
              isSelectionMode: isSelectionMode,
              isSelected: isSelected,
              onSelect: onSelect,
              onLongPress: onLongPress,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('手机多选模式保留封面并显示选中标记', (tester) async {
    await pumpMobileTile(tester, isSelectionMode: true, isSelected: true);

    expect(find.byType(CoverImage), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('点击多选歌曲会切换选择状态', (tester) async {
    var selected = false;
    await pumpMobileTile(
      tester,
      isSelectionMode: true,
      onSelect: () => selected = true,
    );

    await tester.tap(find.text('测试歌曲'));
    await tester.pump();

    expect(selected, isTrue);
  });

  testWidgets('普通模式长按会进入多选流程', (tester) async {
    var longPressed = false;
    await pumpMobileTile(tester, onLongPress: () => longPressed = true);

    await tester.longPress(find.text('测试歌曲'));
    await tester.pump();

    expect(longPressed, isTrue);
  });
}
