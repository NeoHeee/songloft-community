import 'server_discovery_models.dart';
import 'server_discovery_stub.dart'
    if (dart.library.io) 'server_discovery_io.dart' as platform;

export 'server_discovery_models.dart';

Future<List<DiscoveredServer>> discoverSongloftServers({
  Iterable<int> ports = const [58091],
  Duration timeout = const Duration(milliseconds: 700),
  int concurrency = 28,
  ServerDiscoveryProgressCallback? onProgress,
  ServerDiscoveryCancellation? isCancelled,
}) {
  return platform.discoverSongloftServers(
    ports: ports,
    timeout: timeout,
    concurrency: concurrency,
    onProgress: onProgress,
    isCancelled: isCancelled,
  );
}
