import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'server_entry.dart';

class ProbeResult {
  final ServerEntry entry;
  final bool ok;
  final int? statusCode;
  final String? error;

  const ProbeResult({
    required this.entry,
    required this.ok,
    this.statusCode,
    this.error,
  });
}

class ServerProbe {
  static const Duration _defaultTimeout = Duration(milliseconds: 2500);

  /// 并行探测所有 entries 的 `/api/v1/health`，返回**列表索引最小**的可达项。
  /// 全部失败返回 null。整体最长延迟 = timeout。
  static Future<ServerEntry?> pickFirstReachable(
    List<ServerEntry> entries, {
    Duration timeout = _defaultTimeout,
  }) async {
    if (entries.isEmpty) return null;
    final results = await probeAll(entries, timeout: timeout);
    for (var i = 0; i < entries.length; i++) {
      if (results[i].ok) return entries[i];
    }
    return null;
  }

  /// 并行探测所有 entries，返回与输入顺序对应的结果列表。
  static Future<List<ProbeResult>> probeAll(
    List<ServerEntry> entries, {
    Duration timeout = _defaultTimeout,
  }) async {
    return Future.wait(
      entries.map((e) => probeOne(e, timeout: timeout)),
      eagerError: false,
    );
  }

  /// 探测单个 entry。失败折叠为 [ProbeResult.ok] = false，不抛异常。
  static Future<ProbeResult> probeOne(
    ServerEntry entry, {
    Duration timeout = _defaultTimeout,
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: entry.url,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        sendTimeout: timeout,
        headers: const {'Accept': 'application/json'},
      ),
    );
    try {
      final res = await dio.get<dynamic>('/api/v1/health');
      final ok = res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300;
      return ProbeResult(entry: entry, ok: ok, statusCode: res.statusCode);
    } catch (e) {
      debugPrint('[ServerProbe] ${entry.url} 不可达: $e');
      return ProbeResult(entry: entry, ok: false, error: e.toString());
    } finally {
      dio.close(force: true);
    }
  }
}
