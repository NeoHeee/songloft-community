import 'package:flutter/foundation.dart';

import 'theme_pack.dart';

const int supportedThemeCatalogSchemaVersion = 1;
const int maxThemeCatalogEntries = 100;

class ThemeCatalogFormatException implements Exception {
  final String message;

  const ThemeCatalogFormatException(this.message);

  @override
  String toString() => message;
}

enum ThemeCatalogOrigin { remote, bundled }

@immutable
class ThemeCatalog {
  final int schemaVersion;
  final String name;
  final String description;
  final DateTime? generatedAt;
  final List<ThemeCatalogEntry> entries;
  final ThemeCatalogOrigin origin;

  const ThemeCatalog({
    required this.schemaVersion,
    required this.name,
    required this.description,
    required this.generatedAt,
    required this.entries,
    required this.origin,
  });

  factory ThemeCatalog.fromJson(
    Map<String, dynamic> json, {
    ThemeCatalogOrigin origin = ThemeCatalogOrigin.bundled,
  }) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != supportedThemeCatalogSchemaVersion) {
      throw ThemeCatalogFormatException(
        '不支持的主题目录规范版本：$schemaVersion，当前仅支持 '
        '$supportedThemeCatalogSchemaVersion',
      );
    }

    final rawEntries = json['themes'];
    if (rawEntries is! List) {
      throw const ThemeCatalogFormatException('主题目录缺少 themes 数组');
    }
    if (rawEntries.length > maxThemeCatalogEntries) {
      throw const ThemeCatalogFormatException('主题目录最多包含 100 个主题');
    }

    final entries = <ThemeCatalogEntry>[];
    final ids = <String>{};
    for (final rawEntry in rawEntries) {
      if (rawEntry is! Map) {
        throw const ThemeCatalogFormatException('主题目录条目必须是 JSON 对象');
      }
      final entry = ThemeCatalogEntry.fromJson(
        Map<String, dynamic>.from(rawEntry),
      );
      if (!ids.add(entry.id)) {
        throw ThemeCatalogFormatException('主题目录包含重复 id：${entry.id}');
      }
      entries.add(entry);
    }

    entries.sort((a, b) {
      if (a.featured != b.featured) return a.featured ? -1 : 1;
      return a.name.compareTo(b.name);
    });

    final generatedAtValue = json['generatedAt'];
    DateTime? generatedAt;
    if (generatedAtValue != null) {
      if (generatedAtValue is! String) {
        throw const ThemeCatalogFormatException('generatedAt 必须是 ISO 8601 字符串');
      }
      generatedAt = DateTime.tryParse(generatedAtValue);
      if (generatedAt == null) {
        throw const ThemeCatalogFormatException(
          'generatedAt 不是有效的 ISO 8601 时间',
        );
      }
    }

    return ThemeCatalog(
      schemaVersion: schemaVersion as int,
      name: _requiredString(json['name'], 'name', maxLength: 80),
      description: _optionalString(
        json['description'],
        'description',
        maxLength: 240,
      ),
      generatedAt: generatedAt,
      entries: List.unmodifiable(entries),
      origin: origin,
    );
  }

  ThemeCatalog copyWith({ThemeCatalogOrigin? origin}) {
    return ThemeCatalog(
      schemaVersion: schemaVersion,
      name: name,
      description: description,
      generatedAt: generatedAt,
      entries: entries,
      origin: origin ?? this.origin,
    );
  }
}

@immutable
class ThemeCatalogEntry {
  static const Set<String> trustedRemoteHosts = {'raw.githubusercontent.com'};
  static const String trustedRepositoryPathPrefix = '/NeoHeee/songloft-player/';
  static const String trustedAssetPathPrefix = 'assets/theme_catalog/themes/';

  final SongloftThemePack previewPack;
  final List<String> tags;
  final bool featured;
  final Uri downloadUri;
  final String? bundledAsset;
  final String sha256Digest;

  const ThemeCatalogEntry({
    required this.previewPack,
    required this.tags,
    required this.featured,
    required this.downloadUri,
    required this.bundledAsset,
    required this.sha256Digest,
  });

  String get id => previewPack.id;
  String get name => previewPack.name;
  String get version => previewPack.version;
  String get author => previewPack.author;
  String get description => previewPack.description;

  factory ThemeCatalogEntry.fromJson(Map<String, dynamic> json) {
    final previewPack = SongloftThemePack.fromJson({
      'schemaVersion': json['themeSchemaVersion'],
      'id': json['id'],
      'name': json['name'],
      'version': json['version'],
      'author': json['author'],
      'description': json['description'],
      'light': json['light'],
      'dark': json['dark'],
    });
    if (SongloftThemePacks.findBuiltIn(previewPack.id) != null) {
      throw ThemeCatalogFormatException('在线主题不能使用内置主题 id：${previewPack.id}');
    }

    final downloadUrl = _requiredString(
      json['downloadUrl'],
      'downloadUrl',
      maxLength: 400,
    );
    final downloadUri = Uri.tryParse(downloadUrl);
    if (downloadUri == null) {
      throw const ThemeCatalogFormatException('downloadUrl 不是有效地址');
    }
    validateTrustedDownloadUri(downloadUri);

    final rawDigest =
        _requiredString(json['sha256'], 'sha256', maxLength: 64).toLowerCase();
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(rawDigest)) {
      throw const ThemeCatalogFormatException('sha256 必须是 64 位十六进制字符串');
    }

    final bundledAssetValue = json['bundledAsset'];
    String? bundledAsset;
    if (bundledAssetValue != null) {
      bundledAsset = _requiredString(
        bundledAssetValue,
        'bundledAsset',
        maxLength: 240,
      );
      validateBundledAssetPath(bundledAsset);
    }

    final rawTags = json['tags'];
    final tags = <String>[];
    if (rawTags != null) {
      if (rawTags is! List || rawTags.length > 8) {
        throw const ThemeCatalogFormatException('tags 必须是最多包含 8 项的数组');
      }
      for (final value in rawTags) {
        final tag = _requiredString(value, 'tags', maxLength: 20);
        if (!tags.contains(tag)) tags.add(tag);
      }
    }

    final featuredValue = json['featured'];
    if (featuredValue != null && featuredValue is! bool) {
      throw const ThemeCatalogFormatException('featured 必须是布尔值');
    }

    return ThemeCatalogEntry(
      previewPack: previewPack,
      tags: List.unmodifiable(tags),
      featured: featuredValue as bool? ?? false,
      downloadUri: downloadUri,
      bundledAsset: bundledAsset,
      sha256Digest: rawDigest,
    );
  }

  static void validateTrustedDownloadUri(Uri uri) {
    if (uri.scheme != 'https') {
      throw const ThemeCatalogFormatException('主题下载地址必须使用 HTTPS');
    }
    if (!trustedRemoteHosts.contains(uri.host)) {
      throw ThemeCatalogFormatException('不受信任的主题下载域名：${uri.host}');
    }
    if (!uri.path.startsWith(trustedRepositoryPathPrefix)) {
      throw const ThemeCatalogFormatException('主题下载地址不属于受信任的 Songloft 仓库');
    }
    if (uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) {
      throw const ThemeCatalogFormatException('主题下载地址不能包含查询、片段或认证信息');
    }
  }

  static void validateBundledAssetPath(String path) {
    if (!path.startsWith(trustedAssetPathPrefix) ||
        path.contains('..') ||
        path.startsWith('/')) {
      throw const ThemeCatalogFormatException('bundledAsset 不是允许的主题资源路径');
    }
  }
}

String _requiredString(Object? value, String field, {required int maxLength}) {
  if (value is! String || value.trim().isEmpty) {
    throw ThemeCatalogFormatException('$field 不能为空');
  }
  final normalized = value.trim();
  if (normalized.length > maxLength) {
    throw ThemeCatalogFormatException('$field 长度不能超过 $maxLength 个字符');
  }
  return normalized;
}

String _optionalString(Object? value, String field, {required int maxLength}) {
  if (value == null) return '';
  if (value is! String) {
    throw ThemeCatalogFormatException('$field 必须是字符串');
  }
  final normalized = value.trim();
  if (normalized.length > maxLength) {
    throw ThemeCatalogFormatException('$field 长度不能超过 $maxLength 个字符');
  }
  return normalized;
}
