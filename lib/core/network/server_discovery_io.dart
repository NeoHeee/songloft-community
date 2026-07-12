import 'dart:io';
import 'dart:math';

import 'server_discovery_models.dart';

class _ProbeTarget {
  final String host;
  final int port;
  final String network;

  const _ProbeTarget({
    required this.host,
    required this.port,
    required this.network,
  });

  String get url => 'http://$host:$port';
}

Future<List<DiscoveredServer>> discoverSongloftServers({
  required Iterable<int> ports,
  required Duration timeout,
  required int concurrency,
  ServerDiscoveryProgressCallback? onProgress,
  ServerDiscoveryCancellation? isCancelled,
}) async {
  final normalizedPorts =
      ports.where((port) => port > 0 && port <= 65535).toSet().toList()..sort();
  if (normalizedPorts.isEmpty) return const <DiscoveredServer>[];

  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
    includeLinkLocal: false,
  );

  final localAddresses = <String>{};
  final networks = <String>{};
  for (final interface in interfaces) {
    for (final address in interface.addresses) {
      if (!_isPrivateIpv4(address.address)) continue;
      localAddresses.add(address.address);
      final prefix = _networkPrefix(address.address);
      if (prefix != null) networks.add(prefix);
    }
  }

  if (networks.isEmpty) return const <DiscoveredServer>[];

  final targets = <_ProbeTarget>[];
  for (final prefix in networks) {
    final networkLabel = '$prefix.0/24';
    for (var host = 1; host <= 254; host++) {
      final address = '$prefix.$host';
      if (localAddresses.contains(address)) continue;
      for (final port in normalizedPorts) {
        targets.add(
          _ProbeTarget(host: address, port: port, network: networkLabel),
        );
      }
    }
  }

  if (targets.isEmpty) return const <DiscoveredServer>[];

  final client = HttpClient()..connectionTimeout = timeout;
  client.findProxy = (_) => 'DIRECT';

  final found = <String, DiscoveredServer>{};
  var cursor = 0;
  var checked = 0;
  final workerCount = min(max(1, concurrency), targets.length);

  Future<void> worker() async {
    while (true) {
      if (isCancelled?.call() ?? false) return;
      if (cursor >= targets.length) return;

      final target = targets[cursor++];
      final result = await _probeTarget(client, target, timeout);
      if (result != null) found[result.url] = result;

      checked += 1;
      onProgress?.call(
        ServerDiscoveryProgress(
          checked: checked,
          total: targets.length,
          found: found.length,
          network: target.network,
        ),
      );
    }
  }

  try {
    await Future.wait(List.generate(workerCount, (_) => worker()));
  } finally {
    client.close(force: true);
  }

  final results =
      found.values.toList()..sort((a, b) => a.latency.compareTo(b.latency));
  return results;
}

Future<DiscoveredServer?> _probeTarget(
  HttpClient client,
  _ProbeTarget target,
  Duration timeout,
) async {
  final stopwatch = Stopwatch()..start();
  try {
    final uri = Uri.parse('${target.url}/api/v1/health');
    final request = await client.getUrl(uri).timeout(timeout);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(timeout);
    await response.drain<void>().timeout(timeout);
    if (response.statusCode != HttpStatus.ok) return null;

    stopwatch.stop();
    return DiscoveredServer(
      url: target.url,
      host: target.host,
      port: target.port,
      latency: stopwatch.elapsed,
      network: target.network,
    );
  } catch (_) {
    return null;
  } finally {
    if (stopwatch.isRunning) stopwatch.stop();
  }
}

bool _isPrivateIpv4(String value) {
  final parts = value.split('.').map(int.tryParse).toList();
  if (parts.length != 4 || parts.any((part) => part == null)) return false;
  final a = parts[0]!;
  final b = parts[1]!;
  if (a == 10) return true;
  if (a == 172 && b >= 16 && b <= 31) return true;
  if (a == 192 && b == 168) return true;
  return false;
}

String? _networkPrefix(String value) {
  final parts = value.split('.');
  if (parts.length != 4) return null;
  return '${parts[0]}.${parts[1]}.${parts[2]}';
}
