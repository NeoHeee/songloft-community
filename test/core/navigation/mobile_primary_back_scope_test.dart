import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songloft_flutter/config/app_config.dart';
import 'package:songloft_flutter/core/navigation/mobile_primary_back_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AppConfig.isTvMode = false;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    AppConfig.isTvMode = false;
  });

  testWidgets('first back on a primary branch returns to home', (tester) async {
    var returnHomeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MobilePrimaryBackScope(
          onReturnHome: () => returnHomeCount++,
          child: const Scaffold(body: Text('设置')),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(returnHomeCount, 1);
    expect(find.text('设置'), findsOneWidget);
  });

  testWidgets('a real detail route pops before the primary branch scope', (
    tester,
  ) async {
    var returnHomeCount = 0;
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: MobilePrimaryBackScope(
          onReturnHome: () => returnHomeCount++,
          child: const Scaffold(body: Text('歌曲库')),
        ),
      ),
    );

    navigatorKey.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('歌曲详情')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('歌曲详情'), findsNothing);
    expect(find.text('歌曲库'), findsOneWidget);
    expect(returnHomeCount, 0);
  });
}
