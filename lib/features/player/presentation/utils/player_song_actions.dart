import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../shared/utils/responsive_snackbar.dart';
import '../../../../shared/widgets/add_to_playlist_modal.dart';
import '../../../../shared/widgets/delete_song_dialog.dart';
import '../../../library/presentation/providers/favorite_provider.dart';
import '../../../library/presentation/providers/songs_provider.dart';
import '../providers/player_provider.dart';

Future<bool> toggleCurrentSongFavorite(
  BuildContext context,
  WidgetRef ref,
) async {
  final song = ref.read(playerStateProvider).currentSong;
  if (song == null) return false;
  final isRadio = song.type == AppConstants.songTypeRadio;
  try {
    final notifier = ref.read(favoriteProvider.notifier);
    final favorited =
        isRadio
            ? await notifier.toggleRadioFavorite(song.id)
            : await notifier.toggleFavorite(song.id);
    HapticFeedback.selectionClick();
    if (context.mounted) {
      ResponsiveSnackBar.show(
        context,
        message: favorited ? '已添加到收藏' : '已取消收藏',
        duration: const Duration(seconds: 1),
      );
    }
    return favorited;
  } catch (_) {
    if (context.mounted) {
      ResponsiveSnackBar.showError(context, message: '收藏操作失败');
    }
    return false;
  }
}

Future<void> showCurrentSongActionsSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final state = ref.read(playerStateProvider);
  final song = state.currentSong;
  if (song == null) return;
  final isRadio = song.type == AppConstants.songTypeRadio;
  final isFavorited =
      isRadio
          ? ref.read(isRadioFavoritedProvider(song.id))
          : ref.read(isSongFavoritedProvider(song.id));

  final action = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder:
        (sheetContext) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isFavorited
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                title: Text(isFavorited ? '取消收藏' : '收藏歌曲'),
                onTap: () => Navigator.pop(sheetContext, 'favorite'),
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('添加到歌单'),
                onTap: () => Navigator.pop(sheetContext, 'playlist'),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
                title: Text(
                  '删除歌曲',
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.error,
                  ),
                ),
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
            ],
          ),
        ),
  );
  if (!context.mounted || action == null) return;

  switch (action) {
    case 'favorite':
      await toggleCurrentSongFavorite(context, ref);
      break;
    case 'playlist':
      await AddToPlaylistModal.show(context, songIds: [song.id]);
      break;
    case 'delete':
      await deleteCurrentSongFromPlayer(context, ref);
      break;
  }
}

Future<bool> deleteCurrentSongFromPlayer(
  BuildContext context,
  WidgetRef ref,
) async {
  final state = ref.read(playerStateProvider);
  final song = state.currentSong;
  if (song == null) return false;

  final result = await DeleteSongDialog.show(
    context,
    title: '删除歌曲',
    content: '确定要从歌曲库中删除「${song.title}」吗？删除后可在短时间内撤销。',
  );
  if (result == null || !context.mounted) return false;

  final undone = await ResponsiveSnackBar.showUndo(
    context,
    message: '即将删除「${song.title}」',
  );
  if (undone) return false;

  try {
    await ref
        .read(songsApiProvider)
        .deleteSong(song.id, deleteFiles: result.deleteFiles);
    final latest = ref.read(playerStateProvider);
    final index = latest.playlist.indexWhere(
      (item) => item.id == song.id && item.type == song.type,
    );
    if (index >= 0) {
      final notifier = ref.read(playerStateProvider.notifier);
      notifier.removeFromPlaylist(index);
      final nextState = ref.read(playerStateProvider);
      if (index == latest.currentIndex && nextState.currentSong != null) {
        await notifier.playSong(nextState.currentSong!);
      }
    }
    ref.invalidate(songsListProvider);
    if (context.mounted) {
      ResponsiveSnackBar.showSuccess(context, message: '歌曲已删除');
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      ResponsiveSnackBar.showError(context, message: '删除失败');
    }
    return false;
  }
}
