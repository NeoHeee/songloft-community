import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songloft_player/core/theme/accessibility.dart';
import 'package:songloft_player/core/theme/app_theme.dart';

void main() {
  test('mobile theme keeps primary controls at least 48 logical pixels', () {
    final theme = AppTheme.lightTheme();
    final states = <WidgetState>{};
    final iconSize = theme.iconButtonTheme.style?.minimumSize?.resolve(states);
    final filledSize = theme.filledButtonTheme.style?.minimumSize?.resolve(
      states,
    );
    final textSize = theme.textButtonTheme.style?.minimumSize?.resolve(states);

    expect(iconSize?.width, greaterThanOrEqualTo(48));
    expect(iconSize?.height, greaterThanOrEqualTo(48));
    expect(filledSize?.height, greaterThanOrEqualTo(48));
    expect(textSize?.height, greaterThanOrEqualTo(48));
  });

  test('large system text expands navigation and control geometry', () {
    final normal = AppTheme.lightTheme(textScaleFactor: 1.0);
    final large = AppTheme.lightTheme(textScaleFactor: 1.8);
    final states = <WidgetState>{};

    expect(
      large.navigationBarTheme.height,
      greaterThan(normal.navigationBarTheme.height!),
    );
    expect(
      large.appBarTheme.toolbarHeight,
      greaterThan(normal.appBarTheme.toolbarHeight!),
    );
    expect(
      large.filledButtonTheme.style?.minimumSize?.resolve(states)?.height,
      greaterThan(
        normal.filledButtonTheme.style?.minimumSize?.resolve(states)?.height ??
            0,
      ),
    );
  });

  test('reduced motion theme installs no-transition builders', () {
    final theme = AppTheme.darkTheme(reduceMotion: true);
    for (final platform in TargetPlatform.values) {
      expect(
        theme.pageTransitionsTheme.builders[platform].runtimeType.toString(),
        contains('NoTransitionsPageTransitionsBuilder'),
      );
    }
  });

  testWidgets('system accessibility preferences are read and bounded', (
    tester,
  ) async {
    late double scale;
    late bool reduceMotion;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          textScaler: TextScaler.linear(2.6),
          disableAnimations: true,
        ),
        child: Builder(
          builder: (context) {
            scale = AppAccessibility.textScaleOf(context);
            reduceMotion = AppAccessibility.reduceMotionOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(scale, 2.0);
    expect(reduceMotion, isTrue);
  });
}
