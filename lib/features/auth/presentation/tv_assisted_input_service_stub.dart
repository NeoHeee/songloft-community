class TvAssistedCredentials {
  final String apiUrl;
  final String username;
  final String password;

  const TvAssistedCredentials({
    required this.apiUrl,
    required this.username,
    required this.password,
  });
}

/// 非 dart:io 平台占位实现。
///
/// 手机辅助输入仅用于 Android TV 等原生平台；Web 构建通过此实现保持兼容。
class TvAssistedInputService {
  TvAssistedInputService._();

  String get token => '';
  String get pairCode => '';
  DateTime get expiresAt => DateTime.fromMillisecondsSinceEpoch(0);
  Stream<TvAssistedCredentials> get credentials => const Stream.empty();
  String get hostAddress => '';
  int get port => 0;
  String get manualUrl => '';
  String get qrUrl => '';
  bool get isExpired => true;

  static Future<TvAssistedInputService> start({
    Duration validFor = const Duration(minutes: 5),
  }) {
    throw UnsupportedError('当前平台不支持手机辅助输入');
  }

  void allowAnotherSubmission() {}

  Future<void> close() async {}
}
