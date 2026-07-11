import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songloft_flutter/shared/widgets/cover_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('按显示尺寸和 DPR 限制封面缓存位图', (tester) async {
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoverImage(coverUrl: 'https://example.com/cover.jpg', size: 48),
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );

    expect(image.cacheKey, 'https://example.com/cover.jpg');
    expect(image.memCacheWidth, 96);
    expect(image.memCacheHeight, 96);
    expect(image.maxWidthDiskCache, 96);
    expect(image.maxHeightDiskCache, 96);
    expect(image.useOldImageOnUrlChange, isTrue);
    expect(image.fadeInDuration, Duration.zero);
    expect(image.fadeOutDuration, Duration.zero);
  });

  testWidgets('未提供语义标签时封面作为装饰图片跳过读屏', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CoverImage(size: 48))),
    );

    expect(find.byType(ExcludeSemantics), findsOneWidget);
  });

  testWidgets('提供语义标签时向读屏器说明封面内容', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CoverImage(size: 48, semanticLabel: '歌曲《测试》封面')),
      ),
    );

    final semantics = tester.widget<Semantics>(find.byType(Semantics).last);
    expect(semantics.properties.image, isTrue);
    expect(semantics.properties.label, '歌曲《测试》封面');
  });
}
