import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/audio_service.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../main.dart';
import '../../../player/presentation/providers/player_provider.dart';
import '../../data/dlna_service.dart';
import '../../domain/dlna_state.dart';

final dlnaServiceProvider = Provider<DlnaService>((ref) {
  final service = DlnaService();
  ref.onDispose(() => service.dispose());
  return service;
});

final dlnaStateProvider =
    NotifierProvider<DlnaNotifier, DlnaState>(DlnaNotifier.new);

class DlnaNotifier extends Notifier<DlnaState> {
  StreamSubscription? _devicesSub;
  StreamSubscription? _positionSub;

  @override
  DlnaState build() {
    ref.onDispose(() {
      _devicesSub?.cancel();
      _positionSub?.cancel();
    });
    return const DlnaState();
  }

  DlnaService get _service => ref.read(dlnaServiceProvider);
  SongloftAudioHandler get _audioHandler => ref.read(audioHandlerProvider);

  Future<void> startDiscovery() async {
    if (state.isDiscovering) return;
    state = state.copyWith(isDiscovering: true, error: () => null);

    try {
      await _service.startDiscovery();
      _devicesSub?.cancel();
      _devicesSub = _service.devicesStream.listen((devices) {
        state = state.copyWith(devices: devices);
      });
    } catch (e) {
      state = state.copyWith(
        isDiscovering: false,
        error: () => e.toString(),
      );
    }
  }

  void stopDiscovery() {
    _devicesSub?.cancel();
    _service.stopDiscovery();
    state = state.copyWith(isDiscovering: false);
  }

  Future<void> castToDevice(DlnaDeviceInfo device) async {
    final playerState = ref.read(playerStateProvider);
    final song = playerState.currentSong;
    if (song == null || song.url == null) return;

    state = state.copyWith(error: () => null);

    try {
      final url = UrlHelper.buildSongUrl(song.url!, songFormat: song.format);
      await _service.castTo(device.id, url, title: song.title);

      await _audioHandler.pause();

      _positionSub?.cancel();
      _positionSub = _service.positionStream.listen((pos) {
        state = state.copyWith(
          position: Duration(seconds: pos.RelTimeInt),
          duration: Duration(seconds: pos.TrackDurationInt),
        );
      });

      _listenSongChanges();

      state = state.copyWith(
        activeDevice: () => device,
        isCasting: true,
        isPlaying: true,
      );
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  int? _lastSongId;

  void _listenSongChanges() {
    _lastSongId = ref.read(playerStateProvider).currentSong?.id;
    ref.listen(currentSongProvider, (prev, next) {
      if (!state.isCasting || next == null) return;
      if (next.id == _lastSongId) return;
      _lastSongId = next.id;
      if (next.url != null) {
        final url = UrlHelper.buildSongUrl(next.url!, songFormat: next.format);
        _service.castTo(state.activeDevice!.id, url, title: next.title);
      }
    });
  }

  Future<void> togglePlay() async {
    if (!state.isCasting) return;
    try {
      if (state.isPlaying) {
        await _service.pause();
      } else {
        await _service.play();
      }
      state = state.copyWith(isPlaying: !state.isPlaying);
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> seekTo(Duration position) async {
    if (!state.isCasting) return;
    await _service.seek(position);
  }

  Future<void> setVolume(int volume) async {
    if (!state.isCasting) return;
    await _service.setVolume(volume);
  }

  void disconnect() {
    _positionSub?.cancel();
    _service.disconnect();
    state = state.copyWith(
      activeDevice: () => null,
      isCasting: false,
      isPlaying: false,
      position: Duration.zero,
      duration: Duration.zero,
    );
  }
}
