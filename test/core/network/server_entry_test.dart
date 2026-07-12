import 'package:flutter_test/flutter_test.dart';
import 'package:songloft_flutter/core/network/server_entry.dart';

void main() {
  group('ServerEntry.normalizeUrl', () {
    test('保留标准服务器根地址', () {
      expect(
        ServerEntry.normalizeUrl(' http://192.168.1.10:58091/ '),
        'http://192.168.1.10:58091',
      );
    });

    test('自动移除误填的 API 前缀', () {
      expect(
        ServerEntry.normalizeUrl('https://music.example.com/api/v1/'),
        'https://music.example.com',
      );
    });

    test('拒绝缺少协议的地址', () {
      expect(
        () => ServerEntry.normalizeUrl('192.168.1.10:58091'),
        throwsFormatException,
      );
    });
  });
}
