from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding='utf-8')


def write(path: str, content: str) -> None:
    (ROOT / path).write_text(content, encoding='utf-8')


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f'missing patch anchor: {label}')
    return text.replace(old, new, 1)


def patch_adaptive_scaffold() -> None:
    path = 'lib/shared/layouts/adaptive_scaffold.dart'
    text = read(path)
    if 'final VoidCallback? onExitRequested;' not in text:
        text = replace_once(
            text,
            '  final VoidCallback? onClosePlaylistDrawer;\n',
            '  final VoidCallback? onClosePlaylistDrawer;\n  final VoidCallback? onExitRequested;\n',
            'adaptive exit field',
        )
        text = replace_once(
            text,
            '    this.onClosePlaylistDrawer,\n  });',
            '    this.onClosePlaylistDrawer,\n    this.onExitRequested,\n  });',
            'adaptive exit constructor',
        )

    text = replace_once(
        text,
        '''        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('已在首页，按遥控器 Home 键可返回系统桌面'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );''',
        '''        if (onExitRequested != null) {
          onExitRequested!.call();
          return;
        }
        SystemNavigator.pop();''',
        'TV root back exit action',
    )

    text = replace_once(
        text,
        '''                    ),
                  ),
                ],
              ),
            ),''',
        '''                    ),
                  ),
                  if (onExitRequested != null) ...[
                    const SizedBox(width: TvTheme.spacingSmall),
                    _TvNavButton(
                      icon: const Icon(Icons.power_settings_new_rounded),
                      label: '退出',
                      isSelected: false,
                      onPressed: onExitRequested!,
                    ),
                  ],
                ],
              ),
            ),''',
        'TV top exit button',
    )
    write(path, text)


def patch_shell_layout() -> None:
    path = 'lib/shared/layouts/shell_layout.dart'
    text = read(path)
    if 'bool _tvExitDialogOpen = false;' not in text:
        text = replace_once(
            text,
            '  DateTime? _lastBackPressedAt;\n',
            '  DateTime? _lastBackPressedAt;\n  bool _tvExitDialogOpen = false;\n',
            'shell exit dialog state',
        )

    text = replace_once(
        text,
        '''        onClosePlaylistDrawer:
            ref.read(playerStateProvider.notifier).closePlaylistDrawer,
      );''',
        '''        onClosePlaylistDrawer:
            ref.read(playerStateProvider.notifier).closePlaylistDrawer,
        onExitRequested: () => _showTvExitDialog(context),
      );''',
        'shell TV exit callback',
    )

    if 'Future<void> _showTvExitDialog' not in text:
        text = replace_once(
            text,
            '  void _handleMobileRootBack(BuildContext context, String location) {',
            '''  Future<void> _showTvExitDialog(BuildContext context) async {
    if (_tvExitDialogOpen) return;
    _tvExitDialogOpen = true;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(
            Icons.power_settings_new_rounded,
            color: colorScheme.primary,
            size: 40,
          ),
          title: const Text('退出 Songloft？', textAlign: TextAlign.center),
          content: const Text(
            '退出后当前音乐将停止播放，并返回电视系统桌面。播放队列会保留。',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.power_settings_new_rounded),
              label: const Text('退出应用'),
            ),
          ],
        );
      },
    );

    _tvExitDialogOpen = false;
    if (confirmed != true || !mounted) return;

    await ref.read(playerStateProvider.notifier).stopForAppExit();
    if (!mounted) return;
    await SystemNavigator.pop();
  }

  void _handleMobileRootBack(BuildContext context, String location) {''',
            'shell TV exit dialog method',
        )
    write(path, text)


def patch_player_provider() -> None:
    path = 'lib/features/player/presentation/providers/player_provider.dart'
    text = read(path)
    if 'Future<void> stopForAppExit()' in text:
        return

    text = replace_once(
        text,
        '  /// 播放下一首\n  Future<void> playNext() async {',
        '''  /// TV 端退出应用前停止播放，但保留播放队列和当前歌曲信息。
  Future<void> stopForAppExit() async {
    _prefetchCancelToken?.cancel('app exit');
    _loadGeneration++;
    _playGeneration++;
    _stopPositionSaveTimer();
    _sleepTimer?.cancel();
    _sleepTimerCountdown?.cancel();

    try {
      final prefs = await ref.read(appPreferencesProvider.future);
      await prefs.setPositionMs(state.currentTime.inMilliseconds);
    } catch (e) {
      debugPrint('[Player] Failed to save exit position: $e');
    }

    await _audioHandler.stop();
    _liveActivity.endActivity();
    state = state.copyWith(
      isPlaying: false,
      isBuffering: false,
      clearSleepTimer: true,
    );
  }

  /// 播放下一首
  Future<void> playNext() async {''',
        'player exit stop method',
    )
    write(path, text)


def main() -> None:
    patch_adaptive_scaffold()
    patch_shell_layout()
    patch_player_provider()
    print('TV exit flow applied')


if __name__ == '__main__':
    main()
