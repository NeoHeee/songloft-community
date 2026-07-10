import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songloft_flutter/core/theme/theme_pack.dart';

void main() {
  group('SongloftThemePack', () {
    test('parses a valid theme pack', () {
      final pack = SongloftThemePack.fromJson(_validThemeJson());

      expect(pack.id, 'community-test-theme');
      expect(pack.name, '测试主题');
      expect(pack.light.seedColor, const Color(0xFF6750A4));
      expect(pack.dark.backgroundColor, const Color(0xFF101014));
      expect(pack.light.playerGradient, hasLength(2));
      expect(pack.light.cardRadius, 24);
    });

    test('provides safe defaults for optional palette fields', () {
      final json = _validThemeJson();
      final light = Map<String, dynamic>.from(json['light'] as Map);
      light.remove('secondary');
      light.remove('tertiary');
      light.remove('playerGradient');
      light.remove('cardRadius');
      light.remove('controlRadius');
      light.remove('navigationRadius');
      json['light'] = light;

      final pack = SongloftThemePack.fromJson(json);

      expect(pack.light.playerGradient, [
        const Color(0xFF6750A4),
        const Color(0xFF6750A4),
      ]);
      expect(pack.light.cardRadius, 22);
      expect(pack.light.controlRadius, 15);
      expect(pack.light.navigationRadius, 16);
    });

    test('round-trips through pretty JSON', () {
      final original = SongloftThemePack.fromJson(_validThemeJson());
      final restored = SongloftThemePack.fromJsonString(
        original.toPrettyJson(),
      );

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.version, original.version);
      expect(restored.author, original.author);
      expect(restored.description, original.description);
      expect(restored.light.seedColor, original.light.seedColor);
      expect(restored.dark.playerGradient, original.dark.playerGradient);
    });

    test('rejects unsupported schema versions', () {
      final json = _validThemeJson()..['schemaVersion'] = 2;

      expect(
        () => SongloftThemePack.fromJson(json),
        throwsA(
          isA<ThemePackFormatException>().having(
            (error) => error.message,
            'message',
            contains('不支持的主题包规范版本'),
          ),
        ),
      );
    });

    test('rejects invalid theme ids', () {
      final json = _validThemeJson()..['id'] = 'Invalid Theme ID';

      expect(
        () => SongloftThemePack.fromJson(json),
        throwsA(
          isA<ThemePackFormatException>().having(
            (error) => error.message,
            'message',
            contains('id 只能包含'),
          ),
        ),
      );
    });

    test('rejects missing dark palette', () {
      final json = _validThemeJson()..remove('dark');

      expect(
        () => SongloftThemePack.fromJson(json),
        throwsA(
          isA<ThemePackFormatException>().having(
            (error) => error.message,
            'message',
            contains('缺少 dark 配置'),
          ),
        ),
      );
    });

    test('rejects malformed colors', () {
      final json = _validThemeJson();
      final light = Map<String, dynamic>.from(json['light'] as Map);
      light['seed'] = 'purple';
      json['light'] = light;

      expect(
        () => SongloftThemePack.fromJson(json),
        throwsA(
          isA<ThemePackFormatException>().having(
            (error) => error.message,
            'message',
            contains('#RRGGBB'),
          ),
        ),
      );
    });

    test('rejects gradients that do not contain exactly two colors', () {
      final json = _validThemeJson();
      final dark = Map<String, dynamic>.from(json['dark'] as Map);
      dark['playerGradient'] = ['#112233'];
      json['dark'] = dark;

      expect(
        () => SongloftThemePack.fromJson(json),
        throwsA(
          isA<ThemePackFormatException>().having(
            (error) => error.message,
            'message',
            contains('包含两个颜色'),
          ),
        ),
      );
    });

    test('rejects radius values outside the allowed range', () {
      final json = _validThemeJson();
      final light = Map<String, dynamic>.from(json['light'] as Map);
      light['cardRadius'] = 41;
      json['light'] = light;

      expect(
        () => SongloftThemePack.fromJson(json),
        throwsA(
          isA<ThemePackFormatException>().having(
            (error) => error.message,
            'message',
            contains('必须在 0-40 之间'),
          ),
        ),
      );
    });
  });

  group('SongloftThemePacks', () {
    test('built-in ids are unique', () {
      final ids = SongloftThemePacks.builtIn.map((pack) => pack.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
      expect(SongloftThemePacks.findBuiltIn(defaultThemePackId), isNotNull);
    });

    test('all built-in packs can be exported and parsed', () {
      for (final builtIn in SongloftThemePacks.builtIn) {
        final parsed = SongloftThemePack.fromJsonString(builtIn.toPrettyJson());
        expect(parsed.id, builtIn.id);
        expect(parsed.light.playerGradient, hasLength(2));
        expect(parsed.dark.playerGradient, hasLength(2));
      }
    });
  });
}

Map<String, dynamic> _validThemeJson() {
  return {
    'schemaVersion': 1,
    'id': 'community-test-theme',
    'name': '测试主题',
    'version': '1.2.3',
    'author': 'Songloft Tester',
    'description': '用于测试主题包解析和验证。',
    'light': {
      'seed': '#6750A4',
      'background': '#F8F7FC',
      'surface': '#FFFFFF',
      'secondary': '#4C7DFF',
      'tertiary': '#B45CFF',
      'playerGradient': ['#6750A4', '#4C7DFF'],
      'cardRadius': 24,
      'controlRadius': 16,
      'navigationRadius': 17,
    },
    'dark': {
      'seed': '#9C87FF',
      'background': '#101014',
      'surface': '#1B1A22',
      'secondary': '#6E9BFF',
      'tertiary': '#D18AFF',
      'playerGradient': ['#8B6CFF', '#426FE8'],
      'cardRadius': 24,
      'controlRadius': 16,
      'navigationRadius': 17,
    },
  };
}
