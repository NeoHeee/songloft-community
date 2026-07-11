import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/utils/url_helper.dart';

/// 统一封面图组件。
///
/// 所有页面的封面图都应优先使用此组件：
/// - 统一磁盘与内存缓存；
/// - 按实际显示尺寸解码，减少长列表滚动时的内存和 GPU 压力；
/// - URL 中的临时认证参数变化时仍复用同一份缓存；
/// - 不同显示尺寸使用独立缓存档位，避免小图污染全屏大封面；
/// - 默认作为装饰图片跳过读屏器，也可显式提供语义标签。
class CoverImage extends StatelessWidget {
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

    // CachedNetworkImage 默认会按原图尺寸解码。音乐库中大量高分辨率封面同时
    // 出现在列表里时会造成明显内存抖动，因此按逻辑尺寸 × DPR 限制缓存位图。
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final targetPixels =
        (size * devicePixelRatio).round().clamp(1, 2048).toInt();
    final cacheKey =
        hasCover
            ? '${_stableCoverIdentity(rawCoverUrl)}@$targetPixels'
            : null;

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
                    // 去掉临时认证参数后再加入分辨率档位：重新登录不会重复
                    // 缓存，同一封面的小图和全屏大图也不会互相覆盖。
                    cacheKey: cacheKey,
                    fit: fit,
                    memCacheWidth: targetPixels,
                    memCacheHeight: targetPixels,
                    maxWidthDiskCache: targetPixels,
                    maxHeightDiskCache: targetPixels,
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
