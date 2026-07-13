import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songloft_flutter/config/app_config.dart';
import 'package:songloft_flutter/core/navigation/mobile_primary_back_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppConfig.isTvMode = false;
  });

  testWidgets('Android primary branch root installs a non-poppable scope', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MobilePrimaryBackScope(
          onReturnHome: () {},
          child: const Scaffold(body: Text('设置')),
        ),
      ),
    );

    final scopeFinder = find.byWidgetPredicate((widget) => widget is PopScope);
    expect(scopeFinder, findsOneWidget);

    final scope = tester.widget<PopScope>(scopeFinder);
    expect(scope.canPop, isFalse);
    expect(find.text('设置'), findsOneWidget);
  });
}
