from __future__ import annotations

from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f"Could not find startup patch marker: {label}")
    return text.replace(old, new, 1)


def main() -> None:
    path = Path("lib/main.dart")
    text = path.read_text(encoding="utf-8")

    if "runApp(const _NativeBootstrapApp());" not in text:
        text = replace_once(
            text,
            "  WidgetsFlutterBinding.ensureInitialized();\n",
            "  WidgetsFlutterBinding.ensureInitialized();\n\n"
            "  // Windows 原生窗口会在完整初始化前显示。先提交可见首帧，\n"
            "  // 避免桌面插件或凭据初始化缓慢时呈现纯白窗口。\n"
            "  runApp(const _NativeBootstrapApp());\n",
            "WidgetsFlutterBinding",
        )

    if "FileLogger.init().timeout" not in text:
        text = replace_once(
            text,
            "  await FileLogger.init();",
            "  try {\n"
            "    await FileLogger.init().timeout(const Duration(seconds: 3));\n"
            "  } catch (_) {\n"
            "    // 日志初始化失败不能阻止应用继续启动。\n"
            "  }",
            "FileLogger.init",
        )

    if "TvDetector.isTv().timeout" not in text:
        text = replace_once(
            text,
            "  AppConfig.isTvMode = await TvDetector.isTv();",
            "  AppConfig.isTvMode = await TvDetector.isTv().timeout(\n"
            "    const Duration(seconds: 3),\n"
            "    onTimeout: () => false,\n"
            "  );",
            "TvDetector.isTv",
        )

    if "AppPreferences.create().timeout" not in text:
        text = replace_once(
            text,
            "      final prefs = await AppPreferences.create();\n"
            "      await prefs.migrateLegacyApiBaseUrl();",
            "      final prefs = await AppPreferences.create().timeout(\n"
            "        const Duration(seconds: 5),\n"
            "      );\n"
            "      await prefs.migrateLegacyApiBaseUrl().timeout(\n"
            "        const Duration(seconds: 5),\n"
            "      );",
            "AppPreferences.create",
        )

    if "SecureStorageService().getAccessToken().timeout" not in text:
        text = replace_once(
            text,
            "    await SecureStorageService().getAccessToken();",
            "    await SecureStorageService().getAccessToken().timeout(\n"
            "      const Duration(seconds: 5),\n"
            "    );",
            "SecureStorageService.getAccessToken",
        )

    if "class _NativeBootstrapApp extends StatelessWidget" not in text:
        marker = "\nString _generateUserId() {"
        widget = r'''

class _NativeBootstrapApp extends StatelessWidget {
  const _NativeBootstrapApp();

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6750A4);
    return MaterialApp(
      title: 'Songloft',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StartupMark(),
              SizedBox(height: 24),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
              SizedBox(height: 18),
              Text('正在启动 Songloft…'),
              SizedBox(height: 6),
              Text('正在初始化音频与桌面服务'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupMark extends StatelessWidget {
  const _StartupMark();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.tertiaryContainer],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Icon(
        Icons.graphic_eq_rounded,
        size: 40,
        color: colors.primary,
      ),
    );
  }
}
'''
        text = replace_once(text, marker, widget + marker, "_generateUserId")

    path.write_text(text, encoding="utf-8")
    print(f"Patched Windows startup experience: {path}")


if __name__ == "__main__":
    main()
