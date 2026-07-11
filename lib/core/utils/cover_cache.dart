import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import 'url_helper.dart';

/// 封面缓存的统一入口。
///
/// 保证界面展示、播放器背景和调色板提取使用同一套 URL、缓存键和磁盘尺寸，
/// 避免临时认证参数变化导致重复下载，也避免小尺寸调色板请求污染大封面缓存。
abstract final class CoverCache {
  static const int diskExtent = 1024;
  static const int paletteExtent = 100;

  static String? normalizeUrl(String? coverUrl) {
    final normalized = coverUrl?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  static String? displayUrl(String? coverUrl) {
    final normalized = normalizeUrl(coverUrl);
    return normalized == null ? null : UrlHelper.buildCoverUrl(normalized);
  }

  static String? cacheKey(String? coverUrl) {
    final normalized = normalizeUrl(coverUrl);
    if (normalized == null) return null;

    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.queryParameters.isEmpty) return normalized;

    final queryParameters =
        Map<String, String>.from(uri.queryParameters)
          ..remove('access_token')
          ..remove('token');
    return uri
        .replace(
          queryParameters: queryParameters.isEmpty ? null : queryParameters,
        )
        .toString();
  }

  static CachedNetworkImageProvider? provider(String? coverUrl) {
    final url = displayUrl(coverUrl);
    final key = cacheKey(coverUrl);
    if (url == null || key == null) return null;

    return CachedNetworkImageProvider(
      url,
      cacheKey: key,
      maxWidth: diskExtent,
      maxHeight: diskExtent,
    );
  }

  static ImageProvider<Object>? resizedProvider(
    String? coverUrl, {
    required int width,
    required int height,
  }) {
    final imageProvider = provider(coverUrl);
    if (imageProvider == null) return null;
    return ResizeImage(imageProvider, width: width, height: height);
  }
}
