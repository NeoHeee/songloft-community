import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songloft_flutter/core/network/server_connection_provider.dart';

void main() {
  group('server connection classification', () {
    final request = RequestOptions(path: '/api/v1/playlists');

    test('network failures and gateway unavailable responses are tracked', () {
      expect(
        isConnectionFailure(
          DioException(
            requestOptions: request,
            type: DioExceptionType.connectionError,
          ),
        ),
        isTrue,
      );
      expect(
        isConnectionFailure(
          DioException(
            requestOptions: request,
            type: DioExceptionType.badResponse,
            response: Response<void>(requestOptions: request, statusCode: 503),
          ),
        ),
        isTrue,
      );
      expect(isUnavailableStatus(502), isTrue);
      expect(isUnavailableStatus(504), isTrue);
    });

    test('normal HTTP errors still prove the server is reachable', () {
      expect(
        isConnectionFailure(
          DioException(
            requestOptions: request,
            type: DioExceptionType.badResponse,
            response: Response<void>(requestOptions: request, statusCode: 401),
          ),
        ),
        isFalse,
      );
      expect(isUnavailableStatus(500), isFalse);
    });
  });

  test('disconnect and recovery update banner state and generation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(serverConnectionProvider.notifier);
    notifier.reportUnavailable(
      DioException(
        requestOptions: RequestOptions(path: '/api/v1/songs'),
        type: DioExceptionType.connectionTimeout,
      ),
    );

    final disconnected = container.read(serverConnectionProvider);
    expect(disconnected.phase, ServerConnectionPhase.disconnected);
    expect(disconnected.consecutiveFailures, 1);
    expect(disconnected.lastError, '连接服务器超时');

    notifier.reportReachable();
    final recovered = container.read(serverConnectionProvider);
    expect(recovered.phase, ServerConnectionPhase.connected);
    expect(recovered.showRestoredMessage, isTrue);
    expect(recovered.recoveryGeneration, 1);
    expect(recovered.consecutiveFailures, 0);
  });
}
