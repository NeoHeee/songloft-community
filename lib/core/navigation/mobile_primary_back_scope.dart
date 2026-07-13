import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';

import '../../config/app_config.dart';

/// 在 Android 手机端把一级栏目根页面的系统返回键稳定地交给首页。
///
/// 这个作用域必须放在各 StatefulShellBranch 的根页面内部。这样首次直接进入
/// 歌曲库、歌单或设置时，即使该分支没有可弹出的历史页面，也不会让系统直接
/// 退出应用；而分支上方真正存在详情页、对话框或底部弹层时，仍由 Navigator
/// 优先弹出，不会被这里抢走。
class MobilePrimaryBackScope extends StatelessWidget {
  final Widget child;
  final VoidCallback onReturnHome;

  const MobilePrimaryBackScope({
    super.key,
    required this.child,
    required this.onReturnHome,
  });

  bool get _enabled =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      !AppConfig.isTvMode;

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return child;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        FocusManager.instance.primaryFocus?.unfocus();
        ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
        onReturnHome();
      },
      child: child,
    );
  }
}
