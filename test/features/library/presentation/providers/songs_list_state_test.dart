import 'package:flutter_test/flutter_test.dart';
import 'package:songloft_flutter/features/library/presentation/providers/songs_provider.dart';

void main() {
  group('SongsListState selection helpers', () {
    test('全部歌曲被选中时返回 true', () {
      const state = SongsListState(total: 2, selectedSongIds: {1, 2});

      expect(state.isAllSelected, isTrue);
    });

    test('正在全选或仅部分选中时返回 false', () {
      const selecting = SongsListState(
        total: 2,
        selectedSongIds: {1, 2},
        isSelectingAll: true,
      );
      const partial = SongsListState(total: 2, selectedSongIds: {1});

      expect(selecting.isAllSelected, isFalse);
      expect(partial.isAllSelected, isFalse);
    });
  });
}
