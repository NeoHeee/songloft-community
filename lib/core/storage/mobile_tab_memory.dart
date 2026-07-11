/// 进程内保存手机端一级页面的临时现场。
///
/// 仅用于标签页切换时恢复滚动、搜索和筛选，不写入磁盘。
class MobileTabMemory {
  MobileTabMemory._();

  static double homeScrollOffset = 0;
  static double libraryScrollOffset = 0;
  static double playlistsScrollOffset = 0;

  static String librarySearch = '';
  static String playlistsSearch = '';
  static String? playlistType;
}
