class DiscoveredServer {
  final String url;
  final String host;
  final int port;
  final Duration latency;
  final String network;

  const DiscoveredServer({
    required this.url,
    required this.host,
    required this.port,
    required this.latency,
    required this.network,
  });

  String get latencyLabel => '${latency.inMilliseconds} ms';
}

class ServerDiscoveryProgress {
  final int checked;
  final int total;
  final int found;
  final String network;

  const ServerDiscoveryProgress({
    required this.checked,
    required this.total,
    required this.found,
    required this.network,
  });

  double? get fraction => total <= 0 ? null : checked / total;
}

typedef ServerDiscoveryProgressCallback =
    void Function(ServerDiscoveryProgress progress);
typedef ServerDiscoveryCancellation = bool Function();
