from pathlib import Path
import json
import re

BRANCH = "mobile-experience-completion"


def read(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


def write(path: str, text: str) -> None:
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding="utf-8")


def replace_optional(path: str, old: str, new: str) -> None:
    target = Path(path)
    if not target.exists():
        return
    text = target.read_text(encoding="utf-8")
    if old in text:
        target.write_text(text.replace(old, new), encoding="utf-8")


write(
    "lib/config/app_brand.dart",
    """/// Songloft Community 的统一品牌信息。
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
""",
)

pubspec = read("pubspec.yaml")
pubspec = re.sub(
    r"^description:.*$",
    "description: Songloft Community - 社区增强版音乐播放器",
    pubspec,
    flags=re.MULTILINE,
)
pubspec = re.sub(
    r"^version:.*$",
    "version: 1.0.0-community.1+1",
    pubspec,
    flags=re.MULTILINE,
)
pubspec = pubspec.replace(
    'adaptive_icon_background: "#FFFFFF"',
    'adaptive_icon_background: "#6D3DE7"',
)
pubspec = pubspec.replace(
    'adaptive_icon_foreground: "assets/icons/app_icon.png"',
    'adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"',
)
pubspec = pubspec.replace(
    'adaptive_icon_monochrome: "assets/icons/app_icon.png"',
    'adaptive_icon_monochrome: "assets/icons/app_icon_monochrome.png"',
)
if "assets/icons/app_icon_foreground.png" not in pubspec.split("flutter:\n", 1)[1]:
    pubspec = pubspec.replace(
        "    - assets/icons/app_icon.png\n",
        "    - assets/icons/app_icon.png\n"
        "    - assets/icons/app_icon_foreground.png\n"
        "    - assets/icons/app_icon_monochrome.png\n",
    )
write("pubspec.yaml", pubspec)

gradle = read("android/app/build.gradle.kts")
gradle = gradle.replace(
    'namespace = "com.songloft.songloft_flutter"',
    'namespace = "com.neo.songloft.community"',
)
gradle = gradle.replace(
    'applicationId = "com.songloft.songloft_flutter"',
    'applicationId = "com.neo.songloft.community"',
)
write("android/app/build.gradle.kts", gradle)

manifest = read("android/app/src/main/AndroidManifest.xml").replace(
    'android:label="Songloft"',
    'android:label="Songloft Community"',
)
write("android/app/src/main/AndroidManifest.xml", manifest)

old_activity = Path(
    "android/app/src/main/kotlin/com/songloft/songloft_flutter/MainActivity.kt"
)
new_activity = Path(
    "android/app/src/main/kotlin/com/neo/songloft/community/MainActivity.kt"
)
if old_activity.exists():
    activity = old_activity.read_text(encoding="utf-8").replace(
        "package com.songloft.songloft_flutter",
        "package com.neo.songloft.community",
    )
    new_activity.parent.mkdir(parents=True, exist_ok=True)
    new_activity.write_text(activity, encoding="utf-8")
    old_activity.unlink()
elif new_activity.exists():
    activity = new_activity.read_text(encoding="utf-8").replace(
        "package com.songloft.songloft_flutter",
        "package com.neo.songloft.community",
    )
    new_activity.write_text(activity, encoding="utf-8")
else:
    raise SystemExit("MainActivity.kt was not found")

app_config = read("lib/config/app_config.dart")
app_config = app_config.replace(
    "static const String frontendRepo = 'songloft-org/songloft-player';",
    "static const String frontendRepo = 'NeoHeee/songloft-player';",
)
app_config = app_config.replace(
    "'https://github.com/songloft-org/songloft-player/releases/latest';",
    "'https://github.com/NeoHeee/songloft-player/releases/latest';",
)
write("lib/config/app_config.dart", app_config)

main = read("lib/main.dart")
if "import 'config/app_brand.dart';" not in main:
    main = main.replace(
        "import 'config/app_config.dart';",
        "import 'config/app_brand.dart';\nimport 'config/app_config.dart';",
    )
main = main.replace(
    "'songloft_player_instance'",
    "'songloft_community_player_instance'",
)
main = main.replace(
    "androidNotificationChannelId: 'com.songloft.playback'",
    "androidNotificationChannelId: 'com.neo.songloft.community.playback'",
)
main = main.replace(
    "androidNotificationChannelName: 'Songloft 播放控制'",
    "androidNotificationChannelName: 'Songloft Community 播放控制'",
)
main = main.replace("title: 'Songloft'", "title: AppBrand.name")
main = main.replace(
    "Text('正在启动 Songloft…')",
    "Text('正在启动 ${AppBrand.name}…')",
)
main = main.replace(
    "Text('正在初始化音频与桌面服务')",
    "Text(AppBrand.subtitle)",
)
startup_pattern = re.compile(
    r"class _StartupMark extends StatelessWidget \{[\s\S]*?\n\}\n\nString _generateUserId"
)
startup_replacement = """class _StartupMark extends StatelessWidget {
  const _StartupMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Image.asset(
            'assets/icons/app_icon.png',
            width: 96,
            height: 96,
            semanticLabel: AppBrand.name,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          AppBrand.name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        Text(
          AppBrand.subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            AppBrand.edition,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        const Text(AppBrand.version, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

String _generateUserId"""
main, count = startup_pattern.subn(startup_replacement, main, count=1)
if count != 1:
    raise SystemExit(f"Expected one _StartupMark class, found {count}")
write("lib/main.dart", main)

login = read("lib/features/auth/presentation/login_page.dart")
if "import '../../../config/app_brand.dart';" not in login:
    login = login.replace(
        "import '../../../config/app_config.dart';",
        "import '../../../config/app_brand.dart';\n"
        "import '../../../config/app_config.dart';",
    )
login = login.replace("semanticLabel: 'Songloft'", "semanticLabel: AppBrand.name")
login = login.replace(
    "'使用您的账号登录 Songloft'",
    "'使用您的账号登录 ${AppBrand.name}'",
)
login = login.replace(
    "'© ${DateTime.now().year} Songloft'",
    "'© ${DateTime.now().year} ${AppBrand.name}'",
)

tv_brand_pattern = re.compile(
    r"  /// TV 左侧品牌区域\n  Widget _buildTvBranding[\s\S]*?\n  \}\n\n  /// TV 通用输入框"
)
tv_brand_replacement = """  /// TV 左侧品牌区域
  Widget _buildTvBranding(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(38),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/icons/app_icon.png',
            width: 160,
            height: 160,
            semanticLabel: AppBrand.name,
          ),
        ),
        const SizedBox(height: 36),
        Text(
          AppBrand.name,
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            fontSize: 48,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppBrand.subtitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: TvTheme.fontSizeBody,
          ),
        ),
        const SizedBox(height: 16),
        _BrandEditionBadge(colorScheme: colorScheme),
      ],
    );
  }

  /// TV 通用输入框"""
login, count = tv_brand_pattern.subn(tv_brand_replacement, login, count=1)
if count != 1:
    raise SystemExit(f"Expected one TV branding method, found {count}")

mobile_header_pattern = re.compile(
    r"  Widget _buildHeader\(ThemeData theme, ColorScheme colorScheme\) \{[\s\S]*?\n  \}\n\n  Widget _buildUsernameField"
)
mobile_header_replacement = """  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/icons/app_icon.png',
            width: 88,
            height: 88,
            semanticLabel: AppBrand.name,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          AppBrand.name,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppBrand.subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _BrandEditionBadge(colorScheme: colorScheme),
      ],
    );
  }

  Widget _buildUsernameField"""
login, count = mobile_header_pattern.subn(
    mobile_header_replacement,
    login,
    count=1,
)
if count != 1:
    raise SystemExit(f"Expected one mobile branding header, found {count}")

if "class _BrandEditionBadge extends StatelessWidget" not in login:
    login += """

class _BrandEditionBadge extends StatelessWidget {
  final ColorScheme colorScheme;

  const _BrandEditionBadge({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        AppBrand.edition,
        style: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
"""
write("lib/features/auth/presentation/login_page.dart", login)

home = read("lib/features/home/presentation/home_page.dart")
if "import '../../../config/app_brand.dart';" not in home:
    home = home.replace(
        "import '../../../core/router/app_router.dart';",
        "import '../../../config/app_brand.dart';\n"
        "import '../../../core/router/app_router.dart';",
    )
home = home.replace(
    """                          Text(
                            '你的私人音乐空间',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),""",
    """                          Text(
                            AppBrand.edition,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),""",
)
write("lib/features/home/presentation/home_page.dart", home)

settings = read("lib/features/settings/presentation/settings_page.dart")
if "import '../../../config/app_brand.dart';" not in settings:
    settings = settings.replace(
        "import '../../../config/app_config.dart';",
        "import '../../../config/app_brand.dart';\n"
        "import '../../../config/app_config.dart';",
    )
settings = settings.replace("? 'Songloft'", "? AppBrand.name")
about_pattern = re.compile(
    r"  Future<void> _showAboutDialog\(\) async \{[\s\S]*?\n  \}\n\}"
)
about_replacement = """  Future<void> _showAboutDialog() async {
    showAboutDialog(
      context: context,
      applicationName: AppBrand.name,
      applicationVersion: AppBrand.version,
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/icons/app_icon.png',
          width: 52,
          height: 52,
          semanticLabel: AppBrand.name,
        ),
      ),
      applicationLegalese: '© 2026 Songloft Community',
      children: [
        const SizedBox(height: 16),
        Text(
          AppBrand.subtitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            AppBrand.edition,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(AppBrand.declaration),
        const SizedBox(height: 12),
        const SelectableText(
          '包名：${AppBrand.androidPackage}',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 18),
        _aboutRepositoryLink(
          label: '上游开源项目',
          value: 'songloft-org/songloft',
          url: AppBrand.upstreamRepository,
        ),
        const SizedBox(height: 12),
        _aboutRepositoryLink(
          label: '社区版仓库',
          value: 'NeoHeee/songloft-player',
          url: AppBrand.communityRepository,
        ),
      ],
    );
  }

  Widget _aboutRepositoryLink({
    required String label,
    required String value,
    required String url,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      link: true,
      label: '打开 $label',
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(Icons.open_in_new, size: 18, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}"""
settings, count = about_pattern.subn(about_replacement, settings, count=1)
if count != 1:
    raise SystemExit(f"Expected one about dialog method, found {count}")
write("lib/features/settings/presentation/settings_page.dart", settings)

replace_optional(
    "web/index.html",
    "<title>Songloft</title>",
    "<title>Songloft Community</title>",
)
replace_optional(
    "web/index.html",
    'content="Songloft"',
    'content="Songloft Community"',
)
manifest_path = Path("web/manifest.json")
if manifest_path.exists():
    web_manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    web_manifest["name"] = "Songloft Community"
    web_manifest["short_name"] = "Songloft Community"
    web_manifest["description"] = "社区增强版音乐播放器"
    web_manifest["theme_color"] = "#6D3DE7"
    web_manifest["background_color"] = "#171126"
    manifest_path.write_text(
        json.dumps(web_manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

replace_optional(
    "ios/Runner/Info.plist",
    "<string>Songloft</string>",
    "<string>Songloft Community</string>",
)
replace_optional(
    "macos/Runner/Configs/AppInfo.xcconfig",
    "PRODUCT_NAME = songloft_flutter",
    "PRODUCT_NAME = Songloft Community",
)
replace_optional(
    "windows/runner/main.cpp",
    'L"Songloft"',
    'L"Songloft Community"',
)
replace_optional(
    "windows/runner/Runner.rc",
    'VALUE "FileDescription", "Songloft"',
    'VALUE "FileDescription", "Songloft Community"',
)
replace_optional(
    "windows/runner/Runner.rc",
    'VALUE "ProductName", "Songloft"',
    'VALUE "ProductName", "Songloft Community"',
)
replace_optional(
    "linux/runner/my_application.cc",
    '"Songloft"',
    '"Songloft Community"',
)

launch_xml = """<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape android:shape="rectangle">
            <gradient
                android:angle="315"
                android:startColor="@color/launch_background_start"
                android:endColor="@color/launch_background_end" />
        </shape>
    </item>
    <item
        android:width="320dp"
        android:height="190dp"
        android:gravity="center"
        android:drawable="@drawable/launch_brand" />
</layer-list>
"""
write("android/app/src/main/res/drawable/launch_background.xml", launch_xml)
write("android/app/src/main/res/drawable-v21/launch_background.xml", launch_xml)
