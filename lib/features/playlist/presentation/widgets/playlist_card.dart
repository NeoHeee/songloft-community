import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/app_config.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../shared/widgets/tv_focusable.dart';
import '../../domain/playlist.dart';

/// 新版歌单卡片组件
class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onPlayAll;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelect;
  final bool isCurrentPlaylist;
  final bool isPlaying;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;

  const PlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleVisibility,
    this.onPlayAll,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
    this.isCurrentPlaylist = false,
    this.isPlaying = false,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final highlighted = (isSelectionMode && isSelected) || isCurrentPlaylist;

    final content = Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isSelectionMode ? onSelect : onTap,
        onLongPress: isSelectionMode ? null : onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  highlighted
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.24),
              width: highlighted ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildCover(colorScheme),
                        const _BottomCoverGradient(),
                        if (isCurrentPlaylist && isPlaying)
                          Container(
                            color: Colors.black.withValues(alpha: 0.42),
                            child: Center(
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 14,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.equalizer_rounded,
                                  color: colorScheme.onPrimary,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        if (isSelectionMode)
                          Positioned(
                            left: 10,
                            top: 10,
                            child: _SelectionBadge(
                              selected: isSelected,
                              onTap: onSelect,
                            ),
                          )
                        else if (playlist.type == 'radio')
                          const Positioned(
                            left: 10,
                            top: 10,
                            child: _RadioBadge(),
                          ),
                        if (!isSelectionMode && _hasMenu)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: _buildMoreButton(context),
                          ),
                        if (!isSelectionMode && onPlayAll != null)
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: _PlayButton(onPressed: onPlayAll),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final showDescription =
                          playlist.description?.isNotEmpty == true &&
                          constraints.maxHeight >= 76;
                      final showLabels =
                          playlist.labels.isNotEmpty &&
                          constraints.maxHeight >= 100;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color:
                                  isCurrentPlaylist
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                playlist.type == 'radio'
                                    ? Icons.radio_rounded
                                    : Icons.music_note_rounded,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '${playlist.songCount} 首歌曲',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (showDescription) ...[
                            const SizedBox(height: 6),
                            Text(
                              playlist.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (showLabels) ...[
                            const Spacer(),
                            Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              children:
                                  playlist.labels
                                      .take(2)
                                      .map((label) => _LabelChip(label: label))
                                      .toList(),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!AppConfig.isTvMode) return content;
    final action = isSelectionMode ? onSelect : onTap;
    return TvFocusable(
      autofocus: autofocus,
      focusNode: focusNode,
      onFocusChange: onFocusChange,
      onSelect: action,
      onLongSelect: isSelectionMode ? null : onLongPress,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowRight &&
            !isSelectionMode &&
            onLongPress != null) {
          onLongPress!.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      enabled: action != null,
      focusedScale: 1.035,
      borderRadius: 24,
      child: ExcludeFocus(child: content),
    );
  }

  bool get _hasMenu =>
      onEdit != null || onDelete != null || onToggleVisibility != null;

  Widget _buildCover(ColorScheme colorScheme) {
    if (playlist.coverImageUrl == null) {
      return _CoverPlaceholder(isRadio: playlist.type == 'radio');
    }

    return ExcludeSemantics(
      child: CachedNetworkImage(
        imageUrl: UrlHelper.buildCoverUrl(playlist.coverImageUrl!),
        fit: BoxFit.cover,
        placeholder:
            (_, _) => _CoverPlaceholder(isRadio: playlist.type == 'radio'),
        errorWidget:
            (_, _, _) => _CoverPlaceholder(isRadio: playlist.type == 'radio'),
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.black.withValues(alpha: 0.44),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_horiz_rounded,
          size: 21,
          color: Colors.white,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        tooltip: '更多操作',
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit?.call();
              break;
            case 'toggle_visibility':
              onToggleVisibility?.call();
              break;
            case 'delete':
              onDelete?.call();
              break;
          }
        },
        itemBuilder:
            (context) => [
              if (onEdit != null)
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_rounded),
                    title: Text('编辑'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (onToggleVisibility != null && !playlist.isBuiltIn)
                PopupMenuItem(
                  value: 'toggle_visibility',
                  child: ListTile(
                    leading: Icon(
                      playlist.isHidden
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    title: Text(playlist.isHidden ? '取消隐藏' : '隐藏歌单'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (onDelete != null && !playlist.isBuiltIn)
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: colorScheme.error,
                    ),
                    title: Text(
                      '删除',
                      style: TextStyle(color: colorScheme.error),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
      ),
    );
  }
}

class _BottomCoverGradient extends StatelessWidget {
  const _BottomCoverGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0x72000000)],
          stops: [0.58, 1],
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _PlayButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primary,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: Colors.black38,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.play_arrow_rounded,
            color: colorScheme.onPrimary,
            size: 25,
          ),
        ),
      ),
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;

  const _SelectionBadge({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color:
          selected ? colorScheme.primary : Colors.black.withValues(alpha: 0.48),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            selected ? Icons.check_rounded : Icons.circle_outlined,
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _RadioBadge extends StatelessWidget {
  const _RadioBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.radio_rounded,
            size: 14,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 5),
          Text(
            '电台',
            style: TextStyle(
              color: colorScheme.onTertiaryContainer,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final bool isRadio;

  const _CoverPlaceholder({required this.isRadio});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primaryContainer, colorScheme.tertiaryContainer],
        ),
      ),
      child: Center(
        child: Icon(
          isRadio ? Icons.radio_rounded : Icons.graphic_eq_rounded,
          size: 52,
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String label;

  const _LabelChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayLabel = switch (label) {
      'built_in' => '内置',
      'auto_created' => '自动',
      'hidden' => '已隐藏',
      _ => label,
    };
    final background = switch (label) {
      'built_in' => colorScheme.primaryContainer,
      'auto_created' => colorScheme.secondaryContainer,
      'hidden' => colorScheme.errorContainer,
      _ => colorScheme.tertiaryContainer,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
