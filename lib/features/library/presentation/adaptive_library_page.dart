import 'package:flutter/material.dart';

import '../../../core/theme/responsive.dart';
import 'library_page.dart' as legacy;
import 'mobile_library_page.dart';

/// 手机端使用第四轮专用页面，平板与桌面继续复用现有成熟实现。
class AdaptiveLibraryPage extends StatelessWidget {
  const AdaptiveLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return const MobileLibraryPage();
    }
    return const legacy.LibraryPage();
  }
}
