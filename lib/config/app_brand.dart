/// Songloft Community 的统一品牌信息。
///
/// 用户可见名称、版本和社区版声明集中在这里，避免各页面出现不一致。
abstract final class AppBrand {
  static const String name = 'Songloft Community';
  static const String subtitle = '社区增强版音乐播放器';
  static const String edition = 'Community Edition';
  static const String version = '1.0.0-community.1';
  static const String androidPackage = 'com.neo.songloft.community';

  static const String declaration =
      '本应用为基于 Songloft 开源项目开发的社区发行版本，与上游官方发行版相互独立。';

  static const String upstreamRepository =
      'https://github.com/songloft-org/songloft';
  static const String communityRepository =
      'https://github.com/NeoHeee/songloft-player';
}
