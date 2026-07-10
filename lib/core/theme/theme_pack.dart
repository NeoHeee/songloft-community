import 'dart:convert';

import 'package:flutter/material.dart';

const int supportedThemePackSchemaVersion = 1;
const String defaultThemePackId = 'songloft-classic';

/// 主题包格式错误。
class ThemePackFormatException implements Exception {
  final String message;

  const ThemePackFormatException(this.message);

  @override
  String toString() => message;
}

/// 单套明色或暗色主题配置。
@immutable
class SongloftThemePalette {
  final Color seedColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color? secondaryColor;
  final Color? tertiaryColor;
  final List<Color> playerGradient;
  final double cardRadius;
  final double controlRadius;
  final double navigationRadius;

  const SongloftThemePalette({
    required this.seedColor,
    required this.backgroundColor,
    required this.surfaceColor,
    this.secondaryColor,
    this.tertiaryColor,
    required this.playerGradient,
    this.cardRadius = 22,
    this.controlRadius = 15,
    this.navigationRadius = 16,
  });

  factory SongloftThemePalette.fromJson(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final seedColor = _parseColor(json['seed'], '$path.seed');
    final backgroundColor = _parseColor(json['background'], '$path.background');
    final surfaceColor = _parseColor(json['surface'], '$path.surface');
    final secondaryColor = _parseOptionalColor(
      json['secondary'],
      '$path.secondary',
    );
    final tertiaryColor = _parseOptionalColor(
      json['tertiary'],
      '$path.tertiary',
    );

    final gradientValue = json['playerGradient'];
    final gradient = <Color>[];
    if (gradientValue != null) {
      if (gradientValue is! List || gradientValue.length != 2) {
        throw ThemePackFormatException('$path.playerGradient 必须是包含两个颜色的数组');
      }
      gradient.add(_parseColor(gradientValue[0], '$path.playerGradient[0]'));
      gradient.add(_parseColor(gradientValue[1], '$path.playerGradient[1]'));
    } else {
      gradient.add(seedColor);
      gradient.add(tertiaryColor ?? secondaryColor ?? seedColor);
    }

    return SongloftThemePalette(
      seedColor: seedColor,
      backgroundColor: backgroundColor,
      surfaceColor: surfaceColor,
      secondaryColor: secondaryColor,
      tertiaryColor: tertiaryColor,
      playerGradient: List.unmodifiable(gradient),
      cardRadius: _readRadius(json['cardRadius'], 22, '$path.cardRadius'),
      controlRadius: _readRadius(
        json['controlRadius'],
        15,
        '$path.controlRadius',
      ),
      navigationRadius: _readRadius(
        json['navigationRadius'],
        16,
        '$path.navigationRadius',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seed': _colorToHex(seedColor),
      'background': _colorToHex(backgroundColor),
      'surface': _colorToHex(surfaceColor),
      if (secondaryColor != null) 'secondary': _colorToHex(secondaryColor!),
      if (tertiaryColor != null) 'tertiary': _colorToHex(tertiaryColor!),
      'playerGradient': playerGradient.map(_colorToHex).toList(),
      'cardRadius': cardRadius,
      'controlRadius': controlRadius,
      'navigationRadius': navigationRadius,
    };
  }
}

/// Songloft 自定义主题包。
@immutable
class SongloftThemePack {
  final int schemaVersion;
  final String id;
  final String name;
  final String version;
  final String author;
  final String description;
  final SongloftThemePalette light;
  final SongloftThemePalette dark;
  final bool isBuiltIn;

  const SongloftThemePack({
    this.schemaVersion = supportedThemePackSchemaVersion,
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    this.description = '',
    required this.light,
    required this.dark,
    this.isBuiltIn = false,
  });

  factory SongloftThemePack.fromJson(
    Map<String, dynamic> json, {
    bool isBuiltIn = false,
  }) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != supportedThemePackSchemaVersion) {
      throw ThemePackFormatException(
        '不支持的主题包规范版本：$schemaVersion，当前仅支持 '
        '$supportedThemePackSchemaVersion',
      );
    }

    final id = _requiredString(json['id'], 'id', maxLength: 64);
    if (!RegExp(r'^[a-z0-9][a-z0-9._-]{2,63}$').hasMatch(id)) {
      throw const ThemePackFormatException(
        'id 只能包含小写字母、数字、点、下划线和短横线，长度为 3-64 个字符',
      );
    }

    final lightValue = json['light'];
    final darkValue = json['dark'];
    if (lightValue is! Map) {
      throw const ThemePackFormatException('缺少 light 配置');
    }
    if (darkValue is! Map) {
      throw const ThemePackFormatException('缺少 dark 配置');
    }

    return SongloftThemePack(
      schemaVersion: schemaVersion as int,
      id: id,
      name: _requiredString(json['name'], 'name', maxLength: 48),
      version: _requiredString(json['version'], 'version', maxLength: 24),
      author: _requiredString(json['author'], 'author', maxLength: 48),
      description: _optionalString(
        json['description'],
        'description',
        maxLength: 160,
      ),
      light: SongloftThemePalette.fromJson(
        Map<String, dynamic>.from(lightValue),
        path: 'light',
      ),
      dark: SongloftThemePalette.fromJson(
        Map<String, dynamic>.from(darkValue),
        path: 'dark',
      ),
      isBuiltIn: isBuiltIn,
    );
  }

  factory SongloftThemePack.fromJsonString(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        throw const ThemePackFormatException('主题包根节点必须是 JSON 对象');
      }
      return SongloftThemePack.fromJson(Map<String, dynamic>.from(decoded));
    } on ThemePackFormatException {
      rethrow;
    } on FormatException catch (e) {
      throw ThemePackFormatException('主题包 JSON 格式错误：${e.message}');
    } catch (e) {
      throw ThemePackFormatException('无法解析主题包：$e');
    }
  }

  SongloftThemePalette paletteFor(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'id': id,
      'name': name,
      'version': version,
      'author': author,
      if (description.isNotEmpty) 'description': description,
      'light': light.toJson(),
      'dark': dark.toJson(),
    };
  }

  String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}

/// 内置主题包。
class SongloftThemePacks {
  SongloftThemePacks._();

  static const classic = SongloftThemePack(
    id: defaultThemePackId,
    name: 'Songloft 经典',
    version: '1.0.0',
    author: 'Songloft',
    description: '紫蓝色默认主题，兼顾桌面和移动端阅读体验。',
    isBuiltIn: true,
    light: SongloftThemePalette(
      seedColor: Color(0xFF7C5CFF),
      backgroundColor: Color(0xFFF4F5FA),
      surfaceColor: Color(0xFFFFFFFF),
      secondaryColor: Color(0xFF4C7DFF),
      tertiaryColor: Color(0xFFB45CFF),
      playerGradient: [Color(0xFF7C5CFF), Color(0xFF4C7DFF)],
    ),
    dark: SongloftThemePalette(
      seedColor: Color(0xFF9C87FF),
      backgroundColor: Color(0xFF0B0D12),
      surfaceColor: Color(0xFF151821),
      secondaryColor: Color(0xFF6E9BFF),
      tertiaryColor: Color(0xFFD18AFF),
      playerGradient: [Color(0xFF8B6CFF), Color(0xFF426FE8)],
    ),
  );

  static const ocean = SongloftThemePack(
    id: 'songloft-ocean',
    name: '深海蓝',
    version: '1.0.0',
    author: 'Songloft',
    description: '清爽的海蓝与青色组合，适合长时间浏览音乐库。',
    isBuiltIn: true,
    light: SongloftThemePalette(
      seedColor: Color(0xFF1677FF),
      backgroundColor: Color(0xFFF0F7FF),
      surfaceColor: Color(0xFFFFFFFF),
      secondaryColor: Color(0xFF00A8C6),
      tertiaryColor: Color(0xFF5667E8),
      playerGradient: [Color(0xFF1677FF), Color(0xFF00A8C6)],
      cardRadius: 20,
      controlRadius: 14,
      navigationRadius: 15,
    ),
    dark: SongloftThemePalette(
      seedColor: Color(0xFF58A6FF),
      backgroundColor: Color(0xFF06111C),
      surfaceColor: Color(0xFF0E1C2A),
      secondaryColor: Color(0xFF45C7D8),
      tertiaryColor: Color(0xFF8A93FF),
      playerGradient: [Color(0xFF1A73E8), Color(0xFF00A0B8)],
      cardRadius: 20,
      controlRadius: 14,
      navigationRadius: 15,
    ),
  );

  static const forest = SongloftThemePack(
    id: 'songloft-forest',
    name: '森林绿',
    version: '1.0.0',
    author: 'Songloft',
    description: '低饱和绿色与湖蓝搭配，视觉柔和沉静。',
    isBuiltIn: true,
    light: SongloftThemePalette(
      seedColor: Color(0xFF2E8B57),
      backgroundColor: Color(0xFFF3F8F4),
      surfaceColor: Color(0xFFFFFFFF),
      secondaryColor: Color(0xFF278C82),
      tertiaryColor: Color(0xFF6D7F42),
      playerGradient: [Color(0xFF2E8B57), Color(0xFF278C82)],
      cardRadius: 18,
      controlRadius: 13,
      navigationRadius: 14,
    ),
    dark: SongloftThemePalette(
      seedColor: Color(0xFF60B983),
      backgroundColor: Color(0xFF09110D),
      surfaceColor: Color(0xFF121D17),
      secondaryColor: Color(0xFF59BDB0),
      tertiaryColor: Color(0xFFA4B66B),
      playerGradient: [Color(0xFF2F8F5B), Color(0xFF2B8F87)],
      cardRadius: 18,
      controlRadius: 13,
      navigationRadius: 14,
    ),
  );

  static const rose = SongloftThemePack(
    id: 'songloft-rose',
    name: '暮色玫瑰',
    version: '1.0.0',
    author: 'Songloft',
    description: '玫红、橙粉与柔和圆角组成的温暖主题。',
    isBuiltIn: true,
    light: SongloftThemePalette(
      seedColor: Color(0xFFE84A8A),
      backgroundColor: Color(0xFFFFF5F8),
      surfaceColor: Color(0xFFFFFFFF),
      secondaryColor: Color(0xFFF06A6A),
      tertiaryColor: Color(0xFFB45BE0),
      playerGradient: [Color(0xFFE84A8A), Color(0xFFF06A6A)],
      cardRadius: 26,
      controlRadius: 18,
      navigationRadius: 18,
    ),
    dark: SongloftThemePalette(
      seedColor: Color(0xFFFF73A9),
      backgroundColor: Color(0xFF160A11),
      surfaceColor: Color(0xFF24131C),
      secondaryColor: Color(0xFFFF8B7F),
      tertiaryColor: Color(0xFFD68CFF),
      playerGradient: [Color(0xFFE64C8B), Color(0xFFE56A62)],
      cardRadius: 26,
      controlRadius: 18,
      navigationRadius: 18,
    ),
  );

  static const builtIn = [classic, ocean, forest, rose];

  static SongloftThemePack? findBuiltIn(String id) {
    for (final pack in builtIn) {
      if (pack.id == id) return pack;
    }
    return null;
  }
}

Color _parseColor(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw ThemePackFormatException('$field 必须是颜色字符串');
  }
  var hex = value.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8 || !RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(hex)) {
    throw ThemePackFormatException('$field 必须使用 #RRGGBB 或 #AARRGGBB 格式');
  }
  return Color(int.parse(hex, radix: 16));
}

Color? _parseOptionalColor(Object? value, String field) {
  if (value == null) return null;
  return _parseColor(value, field);
}

String _colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

String _requiredString(Object? value, String field, {required int maxLength}) {
  if (value is! String || value.trim().isEmpty) {
    throw ThemePackFormatException('$field 不能为空');
  }
  final result = value.trim();
  if (result.length > maxLength) {
    throw ThemePackFormatException('$field 最多允许 $maxLength 个字符');
  }
  return result;
}

String _optionalString(Object? value, String field, {required int maxLength}) {
  if (value == null) return '';
  if (value is! String) {
    throw ThemePackFormatException('$field 必须是字符串');
  }
  final result = value.trim();
  if (result.length > maxLength) {
    throw ThemePackFormatException('$field 最多允许 $maxLength 个字符');
  }
  return result;
}

double _readRadius(Object? value, double fallback, String field) {
  if (value == null) return fallback;
  if (value is! num) {
    throw ThemePackFormatException('$field 必须是数字');
  }
  final result = value.toDouble();
  if (!result.isFinite || result < 0 || result > 40) {
    throw ThemePackFormatException('$field 必须在 0-40 之间');
  }
  return result;
}
