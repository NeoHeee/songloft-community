import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/utils/url_helper.dart';

/// 统一封面图组件。
///
/// 所有页面的封面图都应优先使用此组件：
/// - 每张封面只保留一份适合播放器展示的磁盘缓存；
/// - 按实际显示尺寸解码内存位图，减少长列表滚动时的内存和 GPU 压力；
/// - URL 中的临时认证参数变化时仍复用同一份缓存；
/// - 默认作为装饰图片跳过读屏器，也可显式提供语义标签。
class CoverImage extends StatelessWidget {
  static const int _diskCacheExtent = 1024;

  /// 完整的封面 URL（后端统一处理）
  final String? coverUrl;

  /// 图片尺寸（宽高相同，方形）
  final double size;

  /// 圆角半径
  final double borderRadius;

  /// 占位符图标
  final IconData placeholderIcon;

  /// 图片填充方式
  final BoxFit fit;

  /// 无障碍语义标签（为 null 时图片被标记为装饰性，读屏器会跳过）
  final String? semanticLabel;

  const CoverImage({
    super.key,
    this.coverUrl,
    this.size = 48,
    this.borderRadius = 8,
    this.placeholderIcon = Icons.music_note,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final rawCoverUrl = coverUrl?.trim();
    final hasCover = rawCoverUrl != null && rawCoverUrl.isNotEmpty;
    final displayUrl = hasCover ? UrlHelper.buildCoverUrl(rawCoverUrl) : null;

    // 磁盘只缓存一份 1024px 封面，足以覆盖手机全屏和大部分桌面展示；
    // 内存位图再按逻辑尺寸 × DPR 解码，避免列表里驻留大量原尺寸图片。
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final targetPixels =
        (size * devicePixelRatio).round().clamp(1, 2048).toInt();
    final cacheKey = hasCover ? _stableCoverIdentity(rawCoverUrl) : null;

    final imageWidget = RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: size,
          height: size,
          child:
              displayUrl != null
                  ? CachedNetworkImage(
                    imageUrl: displayUrl,
                    // 去掉临时认证参数，重新登录或 token 刷新后继续复用缓存。
                    cacheKey: cacheKey,
                    fit: fit,
                    memCacheWidth: targetPixels,
                    memCacheHeight: targetPixels,
                    maxWidthDiskCache: _diskCacheExtent,
                    maxHeightDiskCache: _diskCacheExtent,
                    useOldImageOnUrlChange: true,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (context, url) => _buildPlaceholder(context),
                    errorWidget:
                        (context, url, error) => _buildPlaceholder(context),
                  )
                  : _buildPlaceholder(context),
        ),
      ),
    );

    if (semanticLabel != null && semanticLabel!.trim().isNotEmpty) {
      return Semantics(
        image: true,
        label: semanticLabel!.trim(),
        child: imageWidget,
      );
    }
    return ExcludeSemantics(child: imageWidget);
  }

  String _stableCoverIdentity(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.queryParameters.isEmpty) return url;

    final queryParameters = Map<String, String>.from(uri.queryParameters)
      ..remove('access_token')
      ..remove('token');
    return uri
        .replace(queryParameters: queryParameters.isEmpty ? null : queryParameters)
        .toString();
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          placeholderIcon,
          size: size * 0.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
