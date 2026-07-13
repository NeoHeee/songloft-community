import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/responsive.dart';
import '../../../../shared/utils/responsive_snackbar.dart';
import '../../../../shared/widgets/add_to_playlist_modal.dart';
import '../../../../shared/widgets/delete_song_dialog.dart';
import '../providers/songs_provider.dart';

const double _desktopPageMaxWidth = 1200;

bool _usesDesktopAlignedWidth(BuildContext context) {
  return context.screenWidth >= ResponsiveBreakpoints.desktop &&
      (kIsWeb || defaultTargetPlatform == TargetPlatform.windows);
}

Widget _wrapBarWidth(
  BuildContext context, {
  required Widget child,
  required EdgeInsets mobilePadding,
  required EdgeInsets desktopPadding,
}) {
  if (!_usesDesktopAlignedWidth(context)) {
    return Padding(padding: mobilePadding, child: child);
  }

  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _desktopPageMaxWidth),
      child: Padding(padding: desktopPadding, child: child),
    ),
  );
}

/// 歌曲类型筛选栏；进入多选模式后原位切换为批量操作栏。
class SongFilterBar extends ConsumerWidget {
  final String? currentType;
  final ValueChanged<String?> onTypeChanged;
  final int songCount;
  final Future<void> Function(bool deleteFiles)? onBatchDelete;

  const SongFilterBar({
    super.key,
    this.currentType,
    required this.onTypeChanged,
    this.songCount = 0,
    this.onBatchDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(songsListProvider);
    if (selectionState.isSelectionMode) {
      return _buildSelectionBar(context, ref, selectionState);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bar = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    icon: Icons.apps_rounded,
                    label: '全部',
                    isSelected: currentType == null,
                    onTap: () => onTypeChanged(null),
                  ),
                  _FilterChip(
                    icon: Icons.storage_rounded,
                    label: '本地',
                    isSelected: currentType == AppConstants.songTypeLocal,
                    onTap: () => onTypeChanged(AppConstants.songTypeLocal),
                  ),
                  _FilterChip(
                    icon: Icons.cloud_rounded,
                    label: '网络',
                    isSelected: currentType == AppConstants.songTypeRemote,
                    onTap: () => onTypeChanged(AppConstants.songTypeRemote),
                  ),
                  _FilterChip(
                    icon: Icons.radio_rounded,
                    label: '电台',
                    isSelected: currentType == AppConstants.songTypeRadio,
                    onTap: () => onTypeChanged(AppConstants.songTypeRadio),
                  ),
                ],
              ),
            ),
          ),
          if (songCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                '$songCount 首',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );

    return _wrapBarWidth(
      context,
      mobilePadding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      desktopPadding: const EdgeInsets.fromLTRB(0, 12, 0, 10),
      child: bar,
    );
  }

  Widget _buildSelectionBar(
    BuildContext context,
    WidgetRef ref,
    SongsListState state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedCount = state.selectedSongIds.length;
    final hasSelection = selectedCount > 0;
    final bar = Semantics(
      container: true,
      liveRegion: true,
      label: '多选操作栏，已选择 $selectedCount 首歌曲',
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.library_add_check_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasSelection ? '已选择 $selectedCount 首歌曲' : '请选择要操作的歌曲',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (hasSelection)
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ref.read(songsListProvider.notifier).clearSelection();
                      },
                      child: const Text('清空'),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.isSelectingAll
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(songsListProvider.notifier)
                                  .toggleSelectAll();
                            },
                      icon: state.isSelectingAll
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              state.isAllSelected
                                  ? Icons.deselect_rounded
                                  : Icons.select_all_rounded,
                            ),
                      label: Text(state.isAllSelected ? '取消全选' : '全选'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: hasSelection
                          ? () {
                              HapticFeedback.lightImpact();
                              AddToPlaylistModal.show(
                                context,
                                songIds: state.selectedSongIds.toList(),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.playlist_add_rounded),
                      label: const Text('加入歌单'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: hasSelection
                          ? () => _showBatchDeleteDialog(context, ref)
                          : null,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('删除'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.onErrorContainer,
                        disabledBackgroundColor:
                            colorScheme.surfaceContainerHighest,
                        disabledForegroundColor: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return _wrapBarWidth(
      context,
      mobilePadding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      desktopPadding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      child: bar,
    );
  }

  Future<void> _showBatchDeleteDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    HapticFeedback.mediumImpact();
    final count = ref.read(songsListProvider).selectedSongIds.length;
    final result = await DeleteSongDialog.show(
      context,
      title: '批量删除',
      content: '确定要删除选中的 $count 首歌曲吗？',
    );
    if (result == null) return;

    if (onBatchDelete != null) {
      await onBatchDelete!(result.deleteFiles);
      return;
    }

    final deleted = await ref
        .read(songsListProvider.notifier)
        .batchDeleteSongs(deleteFiles: result.deleteFiles);
    if (!context.mounted) return;

    if (deleted > 0) {
      ResponsiveSnackBar.showSuccess(context, message: '已删除 $deleted 首歌曲');
    } else {
      ResponsiveSnackBar.showError(context, message: '删除失败');
    }
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
