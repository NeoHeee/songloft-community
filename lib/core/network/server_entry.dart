import 'dart:math';

class ServerEntry {
  final String id;
  final String name;
  final String url;
  final String? username;
  final String? password;

  const ServerEntry({
    required this.id,
    required this.name,
    required this.url,
    this.username,
    this.password,
  });

  static String generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(0x7fffffff);
    return '$ts-$rand';
  }

  /// 规范化 URL：去尾斜杠、移除误填的 /api/v1，并校验服务器根地址。
  /// 失败抛 [FormatException]，由 UI 层兜底为 SnackBar。
  static String normalizeUrl(String input) {
    final trimmed = input.trim().replaceAll(RegExp(r'/+$'), '');
    final normalized = trimmed.replaceFirst(RegExp(r'/api/v1$'), '');
    if (normalized.isEmpty) {
      throw const FormatException('URL 不能为空');
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException(
        '请输入以 http:// 或 https:// 开头的服务器根地址',
      );
    }
    return normalized;
  }

  String get displayName {
    if (name.isNotEmpty) return name;
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.host}$port';
  }

  ServerEntry copyWith({
    String? name,
    String? url,
    String? Function()? usernameOverride,
    String? Function()? passwordOverride,
  }) {
    return ServerEntry(
      id: id,
      name: name ?? this.name,
      url: url ?? this.url,
      username: usernameOverride != null ? usernameOverride() : username,
      password: passwordOverride != null ? passwordOverride() : password,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    if (username != null) 'username': username,
    if (password != null) 'password': password,
  };

  factory ServerEntry.fromJson(Map<String, dynamic> json) => ServerEntry(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    url: json['url'] as String,
    username: json['username'] as String?,
    password: json['password'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerEntry &&
          other.id == id &&
          other.name == name &&
          other.url == url;

  @override
  int get hashCode => Object.hash(id, name, url);
}
