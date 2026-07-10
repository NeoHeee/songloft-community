import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'theme_catalog.dart';
import 'theme_pack.dart';
import 'theme_pack_provider.dart';

@immutable
class ThemeCatalogDownload {
  final SongloftThemePack pack;
  final String source;
  final ThemeCatalogOrigin origin;
  final String sha256Digest;

  const ThemeCatalogDownload({
    required this.pack,
    required this.source,
    required this.origin,
    required this.sha256Digest,
  });
}

class ThemeCatalogRepository {
  static const String remoteCatalogUrl =
      'https://raw.githubusercontent.com/NeoHeee/songloft-player/main/'
      'assets/theme_catalog/catalog.json';
  static const String bundledCatalogAsset =
      'assets/theme_catalog/catalog.json';
  static const int maxCatalogBytes = 256 * 1024;

  final Dio _dio;
  final AssetBundle _assetBundle;

  ThemeCatalogRepository({Dio? dio, AssetBundle? assetBundle})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 8),
            ),
          ),
      _assetBundle = assetBundle ?? rootBundle;

  Future<ThemeCatalog> loadCatalog() async {
    try {
      final bytes = await _downloadBytes(
        Uri.parse(remoteCatalogUrl),
        maxBytes: maxCatalogBytes,
      );
      return _parseCatalog(bytes, origin: ThemeCatalogOrigin.remote);
    } catch (error) {
      debugPrint('[ThemeCatalog] 远程目录不可用，使用内置快照：$error');
      final bytes = await _loadAssetBytes(
        bundledCatalogAsset,
        maxBytes: maxCatalogBytes,
      );
      return _parseCatalog(bytes, origin: ThemeCatalogOrigin.bundled);
    }
  }

  Future<ThemeCatalogDownload> downloadTheme(ThemeCatalogEntry entry) async {
    Uint8List bytes;
    ThemeCatalogOrigin origin;
    try {
      bytes = await _downloadBytes(
        entry.downloadUri,
        maxBytes: ThemePackNotifier.maxThemePackBytes,
      );
      origin = ThemeCatalogOrigin.remote;
    } catch (error) {
      final bundledAsset = entry.bundledAsset;
      if (bundledAsset == null) rethrow;
      debugPrint('[ThemeCatalog] 远程主题不可用，使用内置副本：$error');
      bytes = await _loadAssetBytes(
        bundledAsset,
        maxBytes: ThemePackNotifier.maxThemePackBytes,
      );
      origin = ThemeCatalogOrigin.bundled;
    }

    return validateThemeDownload(entry, bytes, origin: origin);
  }

  @visibleForTesting
  ThemeCatalogDownload validateThemeDownload(
    ThemeCatalogEntry entry,
    List<int> bytes, {
    ThemeCatalogOrigin origin = ThemeCatalogOrigin.remote,
  }) {
    if (bytes.isEmpty) {
      throw const ThemeCatalogFormatException('下载的主题包为空');
    }
    if (bytes.length > ThemePackNotifier.maxThemePackBytes) {
      throw const ThemeCatalogFormatException('主题包不能超过 128 KB');
    }

    final digest = sha256.convert(bytes).toString();
    if (digest != entry.sha256Digest) {
      throw const ThemeCatalogFormatException('主题包完整性校验失败，文件可能已被修改');
    }

    var source = utf8.decode(bytes);
    if (source.startsWith('\uFEFF')) source = source.substring(1);
    final pack = SongloftThemePack.fromJsonString(source);
    if (pack.id != entry.id ||
        pack.name != entry.name ||
        pack.version != entry.version ||
        pack.author != entry.author) {
      throw const ThemeCatalogFormatException('下载主题的身份信息与目录清单不一致');
    }
    if (SongloftThemePacks.findBuiltIn(pack.id) != null) {
      throw const ThemeCatalogFormatException('在线主题不能覆盖内置主题');
    }

    return ThemeCatalogDownload(
      pack: pack,
      source: source,
      origin: origin,
      sha256Digest: digest,
    );
  }

  ThemeCatalog _parseCatalog(
    List<int> bytes, {
    required ThemeCatalogOrigin origin,
  }) {
    if (bytes.isEmpty) {
      throw const ThemeCatalogFormatException('主题目录为空');
    }
    if (bytes.length > maxCatalogBytes) {
      throw const ThemeCatalogFormatException('主题目录不能超过 256 KB');
    }

    var source = utf8.decode(bytes);
    if (source.startsWith('\uFEFF')) source = source.substring(1);
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        throw const ThemeCatalogFormatException('主题目录根节点必须是 JSON 对象');
      }
      return ThemeCatalog.fromJson(
        Map<String, dynamic>.from(decoded),
        origin: origin,
      );
    } on ThemeCatalogFormatException {
      rethrow;
    } on FormatException catch (error) {
      throw ThemeCatalogFormatException('主题目录 JSON 格式错误：${error.message}');
    }
  }

  Future<Uint8List> _downloadBytes(
    Uri uri, {
    required int maxBytes,
  }) async {
    ThemeCatalogEntry.validateTrustedDownloadUri(uri);
    final response = await _dio.get<List<int>>(
      uri.toString(),
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        validateStatus: (status) => status == 200,
        headers: const {'Accept': 'application/json, application/octet-stream'},
      ),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw const ThemeCatalogFormatException('远程资源为空');
    }
    if (data.length > maxBytes) {
      throw ThemeCatalogFormatException('远程资源超过 ${maxBytes ~/ 1024} KB 限制');
    }
    return Uint8List.fromList(data);
  }

  Future<Uint8List> _loadAssetBytes(
    String path, {
    required int maxBytes,
  }) async {
    if (path != bundledCatalogAsset) {
      ThemeCatalogEntry.validateBundledAssetPath(path);
    }
    final data = await _assetBundle.load(path);
    if (data.lengthInBytes > maxBytes) {
      throw ThemeCatalogFormatException('内置资源超过 ${maxBytes ~/ 1024} KB 限制');
    }
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
