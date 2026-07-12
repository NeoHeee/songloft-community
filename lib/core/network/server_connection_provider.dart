import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'base_url_provider.dart';

enum ServerConnectionPhase { connected, reconnecting, disconnected }

class ServerConnectionState {
  final ServerConnectionPhase phase;
  final int consecutiveFailures;
  final String? lastError;
  final DateTime? lastChangedAt;
  final bool showRestoredMessage;
  final int recoveryGeneration;

  const ServerConnectionState({
    this.phase = ServerConnectionPhase.connected,
    this.consecutiveFailures = 0,
    this.lastError,
    this.lastChangedAt,
    this.showRestoredMessage = false,
    this.recoveryGeneration = 0,
  });

  bool get isConnected => phase == ServerConnectionPhase.connected;

  ServerConnectionState copyWith({
    ServerConnectionPhase? phase,
    int? consecutiveFailures,
    String? lastError,
    DateTime? lastChangedAt,
    bool? showRestoredMessage,
    int? recoveryGeneration,
    bool clearError = false,
  }) {
    return ServerConnectionState(
      phase: phase ?? this.phase,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastChangedAt: lastChangedAt ?? this.lastChangedAt,
      showRestoredMessage: showRestoredMessage ?? this.showRestoredMessage,
      recoveryGeneration: recoveryGeneration ?? this.recoveryGeneration,
    );
  }
}

class ServerConnectionNotifier extends Notifier<ServerConnectionState> {
  Timer? _retryTimer;
  Timer? _restoredTimer;
  int _probeGeneration = 0;

  @override
  ServerConnectionState build() {
    ref.watch(baseUrlProvider);
    ref.onDispose(() {
      _retryTimer?.cancel();
      _restoredTimer?.cancel();
    });
    return const ServerConnectionState();
  }

  void reportReachable() {
    _retryTimer?.cancel();
    final recovered = state.phase != ServerConnectionPhase.connected;
    final nextGeneration =
        recovered ? state.recoveryGeneration + 1 : state.recoveryGeneration;

    state = state.copyWith(
      phase: ServerConnectionPhase.connected,
      consecutiveFailures: 0,
      lastChangedAt: DateTime.now(),
      showRestoredMessage: recovered,
      recoveryGeneration: nextGeneration,
      clearError: true,
    );

    if (!recovered) return;
    _restoredTimer?.cancel();
    _restoredTimer = Timer(const Duration(seconds: 3), () {
      if (state.recoveryGeneration != nextGeneration) return;
      state = state.copyWith(showRestoredMessage: false);
    });
  }

  void reportUnavailable(Object error) {
    final failures = state.consecutiveFailures + 1;
    state = state.copyWith(
      phase: ServerConnectionPhase.disconnected,
      consecutiveFailures: failures,
      lastError: _friendlyError(error),
      lastChangedAt: DateTime.now(),
      showRestoredMessage: false,
    );
    _scheduleProbe(failures);
  }

  Future<void> retryNow() async {
    _retryTimer?.cancel();
    await _probe();
  }

  void _scheduleProbe(int failures) {
    _retryTimer?.cancel();
    final seconds = switch (failures) {
      <= 1 => 2,
      2 => 4,
      3 => 8,
      _ => 15,
    };
    _retryTimer = Timer(Duration(seconds: seconds), _probe);
  }

  Future<void> _probe() async {
    final generation = ++_probeGeneration;
    state = state.copyWith(
      phase: ServerConnectionPhase.reconnecting,
      lastChangedAt: DateTime.now(),
      showRestoredMessage: false,
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: ref.read(baseUrlProvider),
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
        validateStatus: (_) => true,
      ),
    );

    try {
      final response = await dio.get<void>('');
      if (generation != _probeGeneration) return;
      if (isUnavailableStatus(response.statusCode)) {
        reportUnavailable('服务器返回 ${response.statusCode}');
      } else {
        reportReachable();
      }
    } on DioException catch (error) {
      if (generation != _probeGeneration) return;
      if (error.response != null &&
          !isUnavailableStatus(error.response?.statusCode)) {
        reportReachable();
      } else {
        reportUnavailable(error);
      }
    } finally {
      dio.close(force: true);
    }
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout => '连接服务器超时',
        DioExceptionType.sendTimeout => '发送请求超时',
        DioExceptionType.receiveTimeout => '等待服务器响应超时',
        DioExceptionType.connectionError => '无法连接到服务器',
        DioExceptionType.badCertificate => '服务器证书验证失败',
        _ => error.message ?? '服务器暂时不可用',
      };
    }
    return error.toString();
  }
}

bool isUnavailableStatus(int? statusCode) {
  return statusCode == 502 || statusCode == 503 || statusCode == 504;
}

bool isConnectionFailure(DioException error) {
  if (isUnavailableStatus(error.response?.statusCode)) return true;
  if (error.response != null) return false;

  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError ||
    DioExceptionType.badCertificate => true,
    DioExceptionType.unknown => true,
    DioExceptionType.badResponse || DioExceptionType.cancel => false,
  };
}

class ServerConnectionInterceptor extends Interceptor {
  final VoidCallback onReachable;
  final void Function(DioException error) onUnavailable;

  ServerConnectionInterceptor({
    required this.onReachable,
    required this.onUnavailable,
  });

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (isUnavailableStatus(response.statusCode)) {
      onUnavailable(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        ),
      );
    } else {
      onReachable();
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (isConnectionFailure(err)) {
      onUnavailable(err);
    } else {
      onReachable();
    }
    handler.next(err);
  }
}

final serverConnectionProvider =
    NotifierProvider<ServerConnectionNotifier, ServerConnectionState>(
      ServerConnectionNotifier.new,
    );
