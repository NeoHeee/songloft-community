/// 手机端返回导航的统一路由规则。
class MobileBackPolicy {
  MobileBackPolicy._();

  static const String home = '/';
  static const String library = '/library';
  static const String playlists = '/playlists';
  static const String settings = '/settings';

  /// 这些一级页面含有页面内部的临时层级，需要由页面自身先处理。
  static bool delegatesRootBack(String location) {
    return location == playlists || location == settings;
  }

  /// 路由级详情页面在无法正常 pop 时使用的确定性父页面。
  static String? parentRouteFor(String location) {
    if (location.startsWith('$playlists/') && location != playlists) {
      return playlists;
    }
    if (location.startsWith('$settings/') && location != settings) {
      return settings;
    }
    return null;
  }

  static bool isHome(String location) => location == home;

  static bool isPrimarySection(String location) {
    return location == library ||
        location == playlists ||
        location == settings ||
        location.startsWith('/plugin-tab/');
  }
}

/// 首页和登录页共用的“二次返回退出”时间窗口。
class MobileExitTracker {
  final Duration confirmationWindow;
  DateTime? _lastBackPressedAt;

  MobileExitTracker({
    this.confirmationWindow = const Duration(seconds: 2),
  });

  bool shouldExit(DateTime now) {
    final previous = _lastBackPressedAt;
    _lastBackPressedAt = now;
    return previous != null && now.difference(previous) <= confirmationWindow;
  }

  void reset() {
    _lastBackPressedAt = null;
  }
}
