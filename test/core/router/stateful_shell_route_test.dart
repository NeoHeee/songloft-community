import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:songloft_flutter/core/router/app_router.dart';
import 'package:songloft_flutter/features/auth/domain/auth_state.dart';
import 'package:songloft_flutter/features/auth/presentation/providers/auth_provider.dart';

class _AuthenticatedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState.initial.authenticated();
}

void main() {
  test('main navigation uses five persistent stateful branches', () {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(_AuthenticatedAuthNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    addTearDown(router.dispose);

    final shell =
        router.configuration.routes.whereType<StatefulShellRoute>().single;

    expect(shell.branches, hasLength(5));
    expect(
      shell.branches.map((branch) => (branch.routes.single as GoRoute).path),
      [
        AppRoutes.home,
        AppRoutes.library,
        AppRoutes.playlists,
        AppRoutes.pluginTab,
        AppRoutes.settings,
      ],
    );
  });

  test('playlist and settings details stay inside their own branch stacks', () {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(_AuthenticatedAuthNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    addTearDown(router.dispose);

    final shell =
        router.configuration.routes.whereType<StatefulShellRoute>().single;
    final playlistRoot = shell.branches[2].routes.single as GoRoute;
    final settingsRoot = shell.branches[4].routes.single as GoRoute;

    expect(playlistRoot.routes.whereType<GoRoute>().single.path, ':id');
    expect(
      settingsRoot.routes.whereType<GoRoute>().map((route) => route.path),
      ['servers', 'tab-config', 'duplicate-check', 'plugin-registry'],
    );
  });
}
