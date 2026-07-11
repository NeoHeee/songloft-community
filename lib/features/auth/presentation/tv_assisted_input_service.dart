import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

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

/// 仅在 TV 登录页短时间运行的局域网输入服务。
///
/// 手机与电视处于同一局域网时，手机浏览器可打开临时网页，
/// 将服务器地址、用户名和密码发送到电视。所有数据只保存在内存中。
class TvAssistedInputService {
  TvAssistedInputService._({
    required this.token,
    required this.pairCode,
    required this.expiresAt,
  });

  final String token;
  final String pairCode;
  final DateTime expiresAt;

  final StreamController<TvAssistedCredentials> _credentialsController =
      StreamController<TvAssistedCredentials>.broadcast();

  HttpServer? _server;
  Timer? _expiryTimer;
  String? _hostAddress;
  bool _submitted = false;
  int _failedCodeAttempts = 0;

  Stream<TvAssistedCredentials> get credentials =>
      _credentialsController.stream;

  String get hostAddress => _hostAddress ?? '';
  int get port => _server?.port ?? 0;
  String get manualUrl => 'http://$hostAddress:$port';
  String get qrUrl => '$manualUrl/pair/$token';
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  static Future<TvAssistedInputService> start({
    Duration validFor = const Duration(minutes: 5),
  }) async {
    final random = Random.secure();
    final tokenBytes = List<int>.generate(24, (_) => random.nextInt(256));
    final token = base64UrlEncode(tokenBytes).replaceAll('=', '');
    final pairCode = (100000 + random.nextInt(900000)).toString();
    final service = TvAssistedInputService._(
      token: token,
      pairCode: pairCode,
      expiresAt: DateTime.now().add(validFor),
    );
    await service._start();
    return service;
  }

  Future<void> _start() async {
    _hostAddress = await _findLanAddress();
    if (_hostAddress == null) {
      throw SocketException('未找到可用的局域网 IPv4 地址');
    }

    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0, shared: false);
    _server!.listen(
      _handleRequest,
      onError: (_) {},
      cancelOnError: false,
    );
    _expiryTimer = Timer(expiresAt.difference(DateTime.now()), () {
      unawaited(close());
    });
  }

  Future<String?> _findLanAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );

    final candidates = <String>[];
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (!address.isLoopback) candidates.add(address.address);
      }
    }
    if (candidates.isEmpty) return null;

    for (final address in candidates) {
      if (_isPrivateIpv4(address)) return address;
    }
    return candidates.first;
  }

  bool _isPrivateIpv4(String value) {
    final parts = value.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((part) => part == null)) return false;
    final first = parts[0]!;
    final second = parts[1]!;
    return first == 10 ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    response.headers
      ..set(HttpHeaders.cacheControlHeader, 'no-store, max-age=0')
      ..set('Pragma', 'no-cache')
      ..set('X-Frame-Options', 'DENY')
      ..set(
        'Content-Security-Policy',
        "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; base-uri 'none'",
      );

    try {
      if (isExpired) {
        await _writeHtml(response, _expiredHtml(), statusCode: 410);
        return;
      }

      final path = request.uri.path;
      if (request.method == 'GET' && path == '/') {
        await _writeHtml(response, _pairCodeHtml());
        return;
      }

      if (request.method == 'GET' && path == '/pair/$token') {
        await _writeHtml(response, _credentialsFormHtml(token));
        return;
      }

      if (request.method == 'POST' && path == '/verify') {
        final form = await _readForm(request);
        final code = form['code']?.trim() ?? '';
        if (_failedCodeAttempts >= 5) {
          await _writeHtml(
            response,
            _messageHtml('尝试次数过多', '请在电视端重新生成辅助输入页面。'),
            statusCode: 429,
          );
          return;
        }
        if (code != pairCode) {
          _failedCodeAttempts++;
          await _writeHtml(
            response,
            _pairCodeHtml(error: '配对码不正确，请重新输入。'),
            statusCode: 403,
          );
          return;
        }
        await _writeHtml(response, _credentialsFormHtml(token));
        return;
      }

      if (request.method == 'POST' && path == '/submit') {
        if (_submitted) {
          await _writeHtml(
            response,
            _messageHtml('信息已发送', '请回到电视完成确认。'),
            statusCode: 409,
          );
          return;
        }

        final form = await _readForm(request);
        if (form['token'] != token) {
          await _writeHtml(
            response,
            _messageHtml('链接无效', '请重新扫描电视上的二维码。'),
            statusCode: 403,
          );
          return;
        }

        final apiUrl = (form['apiUrl'] ?? '').trim().replaceAll(
          RegExp(r'/+$'),
          '',
        );
        final username = (form['username'] ?? '').trim();
        final password = form['password'] ?? '';
        final uri = Uri.tryParse(apiUrl);
        if (uri == null ||
            !uri.hasScheme ||
            (uri.scheme != 'http' && uri.scheme != 'https') ||
            uri.host.isEmpty ||
            username.isEmpty ||
            password.isEmpty) {
          await _writeHtml(
            response,
            _credentialsFormHtml(
              token,
              error: '请完整填写有效的服务器地址、用户名和密码。',
              apiUrl: apiUrl,
              username: username,
            ),
            statusCode: 400,
          );
          return;
        }

        _submitted = true;
        _credentialsController.add(
          TvAssistedCredentials(
            apiUrl: apiUrl,
            username: username,
            password: password,
          ),
        );
        await _writeHtml(
          response,
          _messageHtml('已发送到电视', '请回到电视确认登录信息。此页面可以关闭。'),
        );
        return;
      }

      await _writeHtml(
        response,
        _messageHtml('页面不存在', '请重新扫描电视上的二维码。'),
        statusCode: 404,
      );
    } catch (_) {
      try {
        await _writeHtml(
          response,
          _messageHtml('提交失败', '请返回上一页重试。'),
          statusCode: 500,
        );
      } catch (_) {
        // 响应已经开始或连接已断开时无需再次写入。
      }
    } finally {
      await response.close();
    }
  }

  Future<Map<String, String>> _readForm(HttpRequest request) async {
    if (request.contentLength > 64 * 1024) {
      throw const FormatException('请求内容过大');
    }
    final body = await utf8.decoder.bind(request).join();
    return Uri.splitQueryString(body, encoding: utf8);
  }

  Future<void> _writeHtml(
    HttpResponse response,
    String html, {
    int statusCode = 200,
  }) async {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.html;
    response.write(html);
  }

  void allowAnotherSubmission() {
    _submitted = false;
  }

  Future<void> close() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    final server = _server;
    _server = null;
    await server?.close(force: true);
    if (!_credentialsController.isClosed) {
      await _credentialsController.close();
    }
  }

  String _pairCodeHtml({String? error}) {
    return _pageShell(
      title: '连接 Songloft TV',
      body: '''
        <h1>连接 Songloft TV</h1>
        <p class="muted">输入电视屏幕显示的 6 位配对码。</p>
        ${error == null ? '' : '<div class="error">${_escape(error)}</div>'}
        <form method="post" action="/verify">
          <label for="code">配对码</label>
          <input id="code" name="code" inputmode="numeric" pattern="[0-9]{6}" maxlength="6" autocomplete="one-time-code" required autofocus>
          <button type="submit">继续</button>
        </form>
      ''',
    );
  }

  String _credentialsFormHtml(
    String hiddenToken, {
    String? error,
    String apiUrl = '',
    String username = '',
  }) {
    return _pageShell(
      title: '填写登录信息',
      body: '''
        <h1>填写登录信息</h1>
        <p class="muted">信息只会发送到当前局域网中的电视客户端。</p>
        ${error == null ? '' : '<div class="error">${_escape(error)}</div>'}
        <form method="post" action="/submit" autocomplete="on">
          <input type="hidden" name="token" value="${_escape(hiddenToken)}">
          <label for="apiUrl">Songloft 服务器地址</label>
          <input id="apiUrl" name="apiUrl" type="url" value="${_escape(apiUrl)}" placeholder="http://192.168.1.10:3000" required>
          <label for="username">用户名</label>
          <input id="username" name="username" value="${_escape(username)}" autocomplete="username" required>
          <label for="password">密码</label>
          <input id="password" name="password" type="password" autocomplete="current-password" required>
          <button type="submit">发送到电视</button>
        </form>
        <p class="notice">发送后仍需在电视上确认，电视不会在网页中显示密码。</p>
      ''',
    );
  }

  String _expiredHtml() =>
      _messageHtml('辅助输入已过期', '请在电视登录页重新生成。');

  String _messageHtml(String title, String message) {
    return _pageShell(
      title: title,
      body: '''
        <div class="center">
          <div class="success">✓</div>
          <h1>${_escape(title)}</h1>
          <p class="muted">${_escape(message)}</p>
        </div>
      ''',
    );
  }

  String _pageShell({required String title, required String body}) {
    return '''<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>${_escape(title)}</title>
<style>
:root{color-scheme:light dark;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","Noto Sans SC",sans-serif}
*{box-sizing:border-box}body{margin:0;min-height:100vh;display:grid;place-items:center;padding:24px;background:#11131a;color:#f5f2ff}
.card{width:min(100%,520px);padding:28px;border-radius:24px;background:#1b1e29;border:1px solid #343849;box-shadow:0 24px 70px #0008}
h1{margin:0 0 10px;font-size:28px}.muted{color:#b8b9c8;line-height:1.6;margin:0 0 24px}
label{display:block;margin:18px 0 8px;font-weight:700}input{width:100%;padding:15px 16px;border-radius:13px;border:1px solid #4a4f65;background:#11131a;color:#fff;font-size:17px;outline:none}
input:focus{border-color:#a98cff;box-shadow:0 0 0 3px #8d6cff33}button{width:100%;margin-top:24px;padding:16px;border:0;border-radius:14px;background:linear-gradient(90deg,#8d6cff,#4d8cff);color:#fff;font-size:18px;font-weight:800}
.error{padding:12px 14px;border-radius:12px;background:#5b2028;color:#ffd8dc;margin:14px 0}.notice{font-size:13px;color:#a8a9b5;line-height:1.5;margin:18px 0 0}.center{text-align:center}.success{width:72px;height:72px;margin:0 auto 20px;display:grid;place-items:center;border-radius:50%;background:#246b4a;color:#d6ffe9;font-size:38px;font-weight:900}
</style>
</head>
<body><main class="card">$body</main></body>
</html>''';
  }

  String _escape(String value) => const HtmlEscape().convert(value);
}
