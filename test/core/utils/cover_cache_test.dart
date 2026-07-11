import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songloft_flutter/core/utils/cover_cache.dart';

void main() {
  group('CoverCache', () {
    test('空地址和纯空格地址不会创建缓存记录', () {
      expect(CoverCache.normalizeUrl(null), isNull);
      expect(CoverCache.normalizeUrl('   '), isNull);
      expect(CoverCache.cacheKey(''), isNull);
      expect(CoverCache.provider('   '), isNull);
    });

    test('缓存键移除临时令牌并保留业务查询参数', () {
      expect(
        CoverCache.cacheKey(
          'https://example.com/cover.jpg?access_token=abc&token=def&v=2',
        ),
        'https://example.com/cover.jpg?v=2',
      );
    });

    test('只有临时令牌时缓存键不保留空查询串', () {
      expect(
        CoverCache.cacheKey(
          'https://example.com/cover.jpg?access_token=abc&token=def',
        ),
        'https://example.com/cover.jpg',
      );
    });

    test('界面和调色板使用同一种缓存 Provider', () {
      final provider = CoverCache.provider('https://example.com/cover.jpg');
      final resized = CoverCache.resizedProvider(
        'https://example.com/cover.jpg',
        width: CoverCache.paletteExtent,
        height: CoverCache.paletteExtent,
      );

      expect(provider, isA<CachedNetworkImageProvider>());
      expect(resized, isA<ResizeImage>());
    });
  });
}
