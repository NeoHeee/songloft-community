import 'server_discovery_models.dart';

Future<List<DiscoveredServer>> discoverSongloftServers({
  required Iterable<int> ports,
  required Duration timeout,
  required int concurrency,
  ServerDiscoveryProgressCallback? onProgress,
  ServerDiscoveryCancellation? isCancelled,
}) async {
  return const <DiscoveredServer>[];
}
