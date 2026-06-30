import 'dart:async';
import 'package:dlna_dart/dlna.dart';
import 'package:dlna_dart/xmlParser.dart';
import '../domain/dlna_state.dart';

class DlnaService {
  final DLNAManager _manager = DLNAManager();
  DeviceManager? _deviceManager;
  DLNADevice? _activeDevice;
  StreamSubscription? _positionSub;

  final _devicesController =
      StreamController<List<DlnaDeviceInfo>>.broadcast();
  final _positionController =
      StreamController<PositionParser>.broadcast();

  Stream<List<DlnaDeviceInfo>> get devicesStream => _devicesController.stream;
  Stream<PositionParser> get positionStream => _positionController.stream;
  DLNADevice? get activeDevice => _activeDevice;

  Future<void> startDiscovery() async {
    _deviceManager = await _manager.start();
    _deviceManager!.devices.stream.listen((deviceMap) {
      final devices = deviceMap.values
          .map(
            (d) => DlnaDeviceInfo(
              id: d.info.URLBase,
              name: d.info.friendlyName,
              location: d.info.URLBase,
            ),
          )
          .toList();
      _devicesController.add(devices);
    });
  }

  void stopDiscovery() {
    _manager.stop();
    _deviceManager = null;
  }

  Future<void> castTo(
    String deviceId,
    String url, {
    String title = '',
  }) async {
    final device = _deviceManager?.deviceList[deviceId];
    if (device == null) throw Exception('Device not found: $deviceId');

    _activeDevice = device;
    await device.setUrl(url, title: title, type: AudioMime.mp3);
    await device.play();

    _positionSub?.cancel();
    device.positionPoller.start();
    _positionSub = device.currPosition.stream.listen((pos) {
      _positionController.add(pos);
    });
  }

  Future<void> play() async => _activeDevice?.play();
  Future<void> pause() async => _activeDevice?.pause();

  Future<void> stop() async {
    _activeDevice?.positionPoller.stop();
    _positionSub?.cancel();
    await _activeDevice?.stop();
  }

  Future<void> seek(Duration position) async {
    final h = position.inHours.toString().padLeft(2, '0');
    final m = (position.inMinutes % 60).toString().padLeft(2, '0');
    final s = (position.inSeconds % 60).toString().padLeft(2, '0');
    await _activeDevice?.seek('$h:$m:$s');
  }

  Future<void> setVolume(int volume) async =>
      _activeDevice?.volume(volume.clamp(0, 100));

  void disconnect() {
    _positionSub?.cancel();
    _activeDevice?.positionPoller.stop();
    try {
      _activeDevice?.stop();
    } catch (_) {}
    _activeDevice = null;
  }

  void dispose() {
    _positionSub?.cancel();
    _activeDevice?.dispose();
    stopDiscovery();
    _devicesController.close();
    _positionController.close();
  }
}
