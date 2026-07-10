import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songloft_flutter/core/theme/theme_catalog.dart';
import 'package:songloft_flutter/core/theme/theme_catalog_repository.dart';

void main() {
  group('ThemeCatalog', () {
    test('parses a trusted catalog entry', () {
      final themeSource = _themeSource();
      final catalog = ThemeCatalog.fromJson(
        _catalogJson([_entryJson(themeSource)]),
        origin: ThemeCatalogOrigin.remote,
      );

      expect(catalog.origin, ThemeCatalogOrigin.remote);
      expect(catalog.entries, hasLength(1));
      expect(catalog.entries.single.id, 'community-test-catalog');
      expect(catalog.entries.single.tags, ['测试', '蓝色']);
    });

    test('sorts featured themes before regular themes', () {
      final first = _themeSource(id: 'community-first', name: '普通主题');
      final second = _themeSource(id: 'community-second', name: '精选主题');
      final catalog = ThemeCatalog.fromJson(
        _catalogJson([_entryJson(first), _entryJson(second, featured: true)]),
      );

      expect(catalog.entries.first.id, 'community-second');
    });

    test('rejects duplicate theme ids', () {
      final source = _themeSource();

      expect(
        () => ThemeCatalog.fromJson(
          _catalogJson([_entryJson(source), _entryJson(source)]),
        ),
        throwsA(
          isA<ThemeCatalogFormatException>().having(
            (error) => error.message,
            'message',
            contains('重复 id'),
          ),
        ),
      );
    });

    test('rejects non-HTTPS download URLs', () {
      final source = _themeSource();
      final entry = _entryJson(source)
        ..['downloadUrl'] =
            'http://raw.githubusercontent.com/NeoHeee/songloft-player/main/theme';

      expect(
        () => ThemeCatalog.fromJson(_catalogJson([entry])),
        throwsA(
          isA<ThemeCatalogFormatException>().having(
            (error) => error.message,
            'message',
            contains('HTTPS'),
          ),
        ),
      );
    });

    test('rejects untrusted download hosts', () {
      final source = _themeSource();
      final entry = _entryJson(source)
        ..['downloadUrl'] = 'https://example.com/theme.songloft-theme';

      expect(
        () => ThemeCatalog.fromJson(_catalogJson([entry])),
        throwsA(
          isA<ThemeCatalogFormatException>().having(
            (error) => error.message,
            'message',
            contains('不受信任'),
          ),
        ),
      );
    });

    test('rejects bundled asset path traversal', () {
      final source = _themeSource();
      final entry = _entryJson(source)
        ..['bundledAsset'] = 'assets/theme_catalog/themes/../secret.json';

      expect(
        () => ThemeCatalog.fromJson(_catalogJson([entry])),
        throwsA(
          isA<ThemeCatalogFormatException>().having(
            (error) => error.message,
            'message',
            contains('资源路径'),
          ),
        ),
      );
    });
  });

  group('ThemeCatalogRepository', () {
    test('accepts a theme with matching digest and metadata', () {
      final source = _themeSource();
      final entry = ThemeCatalogEntry.fromJson(_entryJson(source));
      final repository = ThemeCatalogRepository();

      final download = repository.validateThemeDownload(
        entry,
        utf8.encode(source),
      );

      expect(download.pack.id, entry.id);
      expect(download.sha256Digest, entry.sha256Digest);
      expect(download.origin, ThemeCatalogOrigin.remote);
    });

    test('rejects a modified theme package', () {
      final source = _themeSource();
      final entry = ThemeCatalogEntry.fromJson(_entryJson(source));
      final repository = ThemeCatalogRepository();

      expect(
        () => repository.validateThemeDownload(entry, utf8.encode('$source ')),
        throwsA(
          isA<ThemeCatalogFormatException>().having(
            (error) => error.message,
            'message',
            contains('完整性校验失败'),
          ),
        ),
      );
    });

    test('rejects metadata that differs from the catalog', () {
      final source = _themeSource();
      final entryJson = _entryJson(source)..['name'] = '目录中的另一个名称';
      final entry = ThemeCatalogEntry.fromJson(entryJson);
      final repository = ThemeCatalogRepository();

      expect(
        () => repository.validateThemeDownload(entry, utf8.encode(source)),
        throwsA(
          isA<ThemeCatalogFormatException>().having(
            (error) => error.message,
            'message',
            contains('身份信息'),
          ),
        ),
      );
    });
  });
}

Map<String, dynamic> _catalogJson(List<Map<String, dynamic>> entries) {
  return {
    'schemaVersion': 1,
    'name': '测试目录',
    'description': '用于验证在线主题目录规则。',
    'generatedAt': '2026-07-10T00:00:00Z',
    'themes': entries,
  };
}

Map<String, dynamic> _entryJson(String themeSource, {bool featured = false}) {
  final theme = Map<String, dynamic>.from(jsonDecode(themeSource) as Map);
  return {
    'themeSchemaVersion': theme['schemaVersion'],
    'id': theme['id'],
    'name': theme['name'],
    'version': theme['version'],
    'author': theme['author'],
    'description': theme['description'],
    'featured': featured,
    'tags': ['测试', '蓝色'],
    'downloadUrl':
        'https://raw.githubusercontent.com/NeoHeee/songloft-player/main/'
        'assets/theme_catalog/themes/${theme['id']}.songloft-theme',
    'bundledAsset': 'assets/theme_catalog/themes/${theme['id']}.songloft-theme',
    'sha256': sha256.convert(utf8.encode(themeSource)).toString(),
    'light': theme['light'],
    'dark': theme['dark'],
  };
}

String _themeSource({
  String id = 'community-test-catalog',
  String name = '目录测试主题',
}) {
  return '${const JsonEncoder.withIndent('  ').convert({
    'schemaVersion': 1,
    'id': id,
    'name': name,
    'version': '1.0.0',
    'author': 'Songloft Tester',
    'description': '用于测试目录下载和校验。',
    'light': {
      'seed': '#3366CC',
      'background': '#F4F7FF',
      'surface': '#FFFFFF',
      'secondary': '#238DA8',
      'tertiary': '#7755CC',
      'playerGradient': ['#3366CC', '#238DA8'],
      'cardRadius': 20,
      'controlRadius': 14,
      'navigationRadius': 15,
    },
    'dark': {
      'seed': '#7FA8FF',
      'background': '#0B101B',
      'surface': '#151D2B',
      'secondary': '#62C7DB',
      'tertiary': '#B59AFF',
      'playerGradient': ['#477CD8', '#237E98'],
      'cardRadius': 20,
      'controlRadius': 14,
      'navigationRadius': 15,
    },
  })}\n';
}
