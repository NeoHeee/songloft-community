import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songloft_flutter/features/library/presentation/widgets/library_actions_sheet.dart';

void main() {
  testWidgets('手机歌曲库操作面板提供排序和维护入口', (tester) async {
    String? selectedSort;
    var toggledHidden = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => LibraryActionsSheet.show(
                  context,
                  currentSort: 'added_at',
                  showHidden: false,
                  onSortChanged: (value) => selectedSort = value,
                  onAddRemote: () {},
                  onAddRadio: () {},
                  onToggleHidden: () => toggledHidden = true,
                  onClean: () {},
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.text('歌曲库操作'), findsOneWidget);
    expect(find.text('添加网络歌曲'), findsOneWidget);
    expect(find.text('添加电台'), findsOneWidget);
    expect(find.text('显示隐藏歌曲'), findsOneWidget);
    expect(find.text('清理无效记录'), findsOneWidget);

    await tester.tap(find.text('艺术家'));
    await tester.pumpAndSettle();
    expect(selectedSort, 'artist');

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('显示隐藏歌曲'));
    await tester.pumpAndSettle();
    expect(toggledHidden, isTrue);
  });
}
