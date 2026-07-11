from __future__ import annotations

import base64
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f"missing patch anchor: {label}")
    return text.replace(old, new, 1)


def patch_app_config() -> None:
    path = "lib/config/app_config.dart"
    text = read(path)
    if "static bool isTvMode = false;" in text:
        return
    text = replace_once(
        text,
        "  static late final bool isTvMode;",
        "  static bool isTvMode = false;",
        "AppConfig.isTvMode",
    )
    write(path, text)


def patch_responsive() -> None:
    path = "lib/core/theme/responsive.dart"
    text = read(path)
    if "AppConfig.isTvMode ||" in text:
        return
    text = replace_once(
        text,
        "import 'package:flutter/material.dart';\n",
        "import 'package:flutter/material.dart';\n\nimport '../../config/app_config.dart';\n",
        "responsive import",
    )
    text = replace_once(
        text,
        "  bool get isTv => screenWidth >= ResponsiveBreakpoints.tv;",
        "  bool get isTv =>\n      AppConfig.isTvMode || screenWidth >= ResponsiveBreakpoints.tv;",
        "responsive isTv",
    )
    text = replace_once(
        text,
        "  ScreenType get screenType {\n"
        "    // 车机模式优先于其他宽屏断点（desktop/tv），因为它靠宽高比区分\n"
        "    if (isAuto) return ScreenType.auto_;\n"
        "    if (isTv) return ScreenType.tv;",
        "  ScreenType get screenType {\n"
        "    // 设备检测到 Android TV 后强制使用 TV 布局，避免 4K 电视因\n"
        "    // 逻辑分辨率较低而误进入桌面或平板布局。\n"
        "    if (AppConfig.isTvMode) return ScreenType.tv;\n"
        "    // 非 TV 设备继续按宽高比识别车机，再按宽度断点识别大屏。\n"
        "    if (isAuto) return ScreenType.auto_;\n"
        "    if (isTv) return ScreenType.tv;",
        "responsive screenType",
    )
    write(path, text)


def patch_tv_focusable() -> None:
    path = "lib/shared/widgets/tv_focusable.dart"
    text = read(path)
    if "final bool scrollIntoView;" in text:
        return
    text = replace_once(
        text,
        "  /// 焦点变化回调\n  final ValueChanged<bool>? onFocusChange;\n",
        "  /// 焦点变化回调\n"
        "  final ValueChanged<bool>? onFocusChange;\n\n"
        "  /// 获得焦点时自动滚动到可视区域\n"
        "  final bool scrollIntoView;\n",
        "TvFocusable field",
    )
    text = replace_once(
        text,
        "    this.enabled = true,\n    this.onFocusChange,\n  });",
        "    this.enabled = true,\n"
        "    this.onFocusChange,\n"
        "    this.scrollIntoView = true,\n"
        "  });",
        "TvFocusable constructor",
    )
    text = replace_once(
        text,
        "      onFocusChange: (hasFocus) {\n"
        "        setState(() {\n"
        "          _hasFocus = hasFocus;\n"
        "        });\n"
        "        widget.onFocusChange?.call(hasFocus);\n"
        "      },",
        "      onFocusChange: (hasFocus) {\n"
        "        setState(() {\n"
        "          _hasFocus = hasFocus;\n"
        "        });\n"
        "        if (hasFocus && widget.scrollIntoView) {\n"
        "          WidgetsBinding.instance.addPostFrameCallback((_) {\n"
        "            if (!mounted) return;\n"
        "            Scrollable.ensureVisible(\n"
        "              context,\n"
        "              alignment: 0.35,\n"
        "              duration: const Duration(milliseconds: 180),\n"
        "              curve: Curves.easeOutCubic,\n"
        "            );\n"
        "          });\n"
        "        }\n"
        "        widget.onFocusChange?.call(hasFocus);\n"
        "      },",
        "TvFocusable auto scroll",
    )
    write(path, text)


def patch_song_list_tile() -> None:
    path = "lib/features/library/presentation/widgets/song_list_tile.dart"
    text = read(path)
    if "AppConfig.isTvMode" in text:
        return
    text = replace_once(
        text,
        "import 'package:flutter_riverpod/flutter_riverpod.dart';\n\n"
        "import '../../../../config/constants.dart';",
        "import 'package:flutter_riverpod/flutter_riverpod.dart';\n\n"
        "import '../../../../config/app_config.dart';\n"
        "import '../../../../config/constants.dart';",
        "SongListTile AppConfig import",
    )
    text = replace_once(
        text,
        "import '../../../../shared/widgets/favorite_button.dart';",
        "import '../../../../shared/widgets/favorite_button.dart';\n"
        "import '../../../../shared/widgets/tv_focusable.dart';",
        "SongListTile TvFocusable import",
    )
    old = """  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (context.isMobile ||
            constraints.maxWidth < ResponsiveBreakpoints.tablet) {
          return _buildMobileLayout(context);
        }
        return _buildDesktopLayout(context);
      },
    );
  }
"""
    new = """  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        if (context.isMobile ||
            constraints.maxWidth < ResponsiveBreakpoints.tablet) {
          return _buildMobileLayout(context);
        }
        return _buildDesktopLayout(context);
      },
    );

    if (!AppConfig.isTvMode) return content;
    final action = isSelectionMode ? onSelect : onTap;
    return TvFocusable(
      autofocus: index == 0,
      onSelect: action,
      enabled: action != null,
      focusedScale: 1.015,
      borderRadius: 18,
      child: ExcludeFocus(child: content),
    );
  }
"""
    text = replace_once(text, old, new, "SongListTile TV wrapper")
    write(path, text)


def patch_playlist_card() -> None:
    path = "lib/features/playlist/presentation/widgets/playlist_card.dart"
    text = read(path)
    if "final bool autofocus;" in text:
        return
    text = replace_once(
        text,
        "import 'package:flutter/material.dart';\n\n"
        "import '../../../../core/utils/url_helper.dart';",
        "import 'package:flutter/material.dart';\n\n"
        "import '../../../../config/app_config.dart';\n"
        "import '../../../../core/utils/url_helper.dart';",
        "PlaylistCard AppConfig import",
    )
    text = replace_once(
        text,
        "import '../../../../core/utils/url_helper.dart';\n"
        "import '../../domain/playlist.dart';",
        "import '../../../../core/utils/url_helper.dart';\n"
        "import '../../../../shared/widgets/tv_focusable.dart';\n"
        "import '../../domain/playlist.dart';",
        "PlaylistCard TvFocusable import",
    )
    text = replace_once(
        text,
        "  final bool isPlaying;\n",
        "  final bool isPlaying;\n  final bool autofocus;\n",
        "PlaylistCard autofocus field",
    )
    text = replace_once(
        text,
        "    this.isCurrentPlaylist = false,\n    this.isPlaying = false,\n  });",
        "    this.isCurrentPlaylist = false,\n"
        "    this.isPlaying = false,\n"
        "    this.autofocus = false,\n"
        "  });",
        "PlaylistCard autofocus ctor",
    )
    text = replace_once(text, "    return Material(\n", "    final content = Material(\n", "PlaylistCard content")
    marker = "\n  bool get _hasMenu =>"
    head, tail = text.split(marker, 1)
    close = "    );\n  }\n"
    pos = head.rfind(close)
    if pos < 0:
        raise RuntimeError("missing PlaylistCard build close")
    replacement = """    );

    if (!AppConfig.isTvMode) return content;
    final action = isSelectionMode ? onSelect : onTap;
    return TvFocusable(
      autofocus: autofocus,
      onSelect: action,
      enabled: action != null,
      focusedScale: 1.035,
      borderRadius: 24,
      child: ExcludeFocus(child: content),
    );
  }
"""
    head = head[:pos] + replacement + head[pos + len(close) :]
    write(path, head + marker + tail)


def patch_playlist_list_item() -> None:
    path = "lib/features/playlist/presentation/widgets/playlist_list_item.dart"
    text = read(path)
    if "final bool autofocus;" in text:
        return
    text = replace_once(
        text,
        "import 'package:flutter/material.dart';\n\n"
        "import '../../../../core/utils/url_helper.dart';",
        "import 'package:flutter/material.dart';\n\n"
        "import '../../../../config/app_config.dart';\n"
        "import '../../../../core/utils/url_helper.dart';",
        "PlaylistListItem AppConfig import",
    )
    text = replace_once(
        text,
        "import '../../../../core/utils/url_helper.dart';\n"
        "import '../../domain/playlist.dart';",
        "import '../../../../core/utils/url_helper.dart';\n"
        "import '../../../../shared/widgets/tv_focusable.dart';\n"
        "import '../../domain/playlist.dart';",
        "PlaylistListItem TvFocusable import",
    )
    text = replace_once(
        text,
        "  final bool isPlaying;\n",
        "  final bool isPlaying;\n  final bool autofocus;\n",
        "PlaylistListItem autofocus field",
    )
    text = replace_once(
        text,
        "    this.isCurrentPlaylist = false,\n    this.isPlaying = false,\n  });",
        "    this.isCurrentPlaylist = false,\n"
        "    this.isPlaying = false,\n"
        "    this.autofocus = false,\n"
        "  });",
        "PlaylistListItem autofocus ctor",
    )
    text = replace_once(text, "    return Padding(\n", "    final content = Padding(\n", "PlaylistListItem content")
    marker = "\n  String get _subtitle"
    head, tail = text.split(marker, 1)
    close = "    );\n  }\n"
    pos = head.rfind(close)
    if pos < 0:
        raise RuntimeError("missing PlaylistListItem build close")
    replacement = """    );

    if (!AppConfig.isTvMode) return content;
    final action = isSelectionMode ? onSelect : onTap;
    return TvFocusable(
      autofocus: autofocus,
      onSelect: action,
      enabled: action != null,
      focusedScale: 1.02,
      borderRadius: 20,
      child: ExcludeFocus(child: content),
    );
  }
"""
    head = head[:pos] + replacement + head[pos + len(close) :]
    write(path, head + marker + tail)


def patch_playlists_page() -> None:
    path = "lib/features/playlist/presentation/playlists_page.dart"
    text = read(path)
    if "autofocus: index == 0," in text:
        return
    text = replace_once(
        text,
        "          return PlaylistCard(\n            playlist: playlist,",
        "          return PlaylistCard(\n"
        "            playlist: playlist,\n"
        "            autofocus: index == 0,",
        "PlaylistsPage card autofocus",
    )
    text = replace_once(
        text,
        "          return PlaylistListItem(\n            playlist: playlist,",
        "          return PlaylistListItem(\n"
        "            playlist: playlist,\n"
        "            autofocus: index == 0,",
        "PlaylistsPage list autofocus",
    )
    write(path, text)


def patch_playlist_detail() -> None:
    path = "lib/features/playlist/presentation/playlist_detail_page.dart"
    text = read(path)
    if "AppConfig.isTvMode || showDragHandle" in text:
        return
    text = replace_once(
        text,
        "import 'package:go_router/go_router.dart';\n\n"
        "import '../../../core/theme/responsive.dart';",
        "import 'package:go_router/go_router.dart';\n\n"
        "import '../../../config/app_config.dart';\n"
        "import '../../../core/theme/responsive.dart';",
        "PlaylistDetail AppConfig import",
    )
    text = replace_once(
        text,
        "import '../../../shared/widgets/song_picker_modal.dart';",
        "import '../../../shared/widgets/song_picker_modal.dart';\n"
        "import '../../../shared/widgets/tv_focusable.dart';",
        "PlaylistDetail TvFocusable import",
    )
    marker = "class _PlaylistSongTile extends StatelessWidget {"
    before, section = text.split(marker, 1)
    section = replace_once(section, "    return Padding(\n", "    final tile = Padding(\n", "PlaylistSongTile content")
    end_marker = "\nclass _SongCover extends StatelessWidget {"
    tile_part, after = section.split(end_marker, 1)
    close = "    );\n  }\n}\n"
    pos = tile_part.rfind(close)
    if pos < 0:
        raise RuntimeError("missing PlaylistSongTile build close")
    replacement = """    );

    if (!AppConfig.isTvMode || showDragHandle) return tile;
    final action = selectionMode ? onSelected : onTap;
    return TvFocusable(
      autofocus: index == 0,
      onSelect: action,
      enabled: action != null,
      focusedScale: 1.015,
      borderRadius: 17,
      child: ExcludeFocus(child: tile),
    );
  }
}
"""
    tile_part = tile_part[:pos] + replacement + tile_part[pos + len(close) :]
    write(path, before + marker + tile_part + end_marker + after)


def patch_adaptive_scaffold() -> None:
    path = "lib/shared/layouts/adaptive_scaffold.dart"
    text = read(path)
    if "final VoidCallback? onClosePlaylistDrawer;" not in text:
        text = replace_once(
            text,
            "  final Widget? playlistDrawer;\n",
            "  final Widget? playlistDrawer;\n"
            "  final VoidCallback? onClosePlaylistDrawer;\n",
            "AdaptiveScaffold close drawer field",
        )
        text = replace_once(
            text,
            "    this.bottomPlayer,\n    this.playlistDrawer,\n  });",
            "    this.bottomPlayer,\n"
            "    this.playlistDrawer,\n"
            "    this.onClosePlaylistDrawer,\n"
            "  });",
            "AdaptiveScaffold close drawer ctor",
        )
    old_back = """        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        }
        // 一级页面不做任何操作，防止退出应用
"""
    new_back = """        if (playlistDrawer != null) {
          onClosePlaylistDrawer?.call();
          return;
        }
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
          return;
        }
        if (currentIndex != 0) {
          onDestinationSelected(0);
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('已在首页，按遥控器 Home 键可返回系统桌面'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
"""
    if old_back in text:
        text = text.replace(old_back, new_back, 1)
    elif "已在首页，按遥控器 Home 键可返回系统桌面" not in text:
        raise RuntimeError("missing TV back handler")
    text = text.replace("autofocus: index == 0,", "autofocus: index == currentIndex,", 1)
    write(path, text)


def patch_shell_layout() -> None:
    path = "lib/shared/layouts/shell_layout.dart"
    text = read(path)
    if "onClosePlaylistDrawer:" in text:
        return
    first = """      return AdaptiveScaffold(
        body: body,
        currentIndex: currentIndex,
        destinations: activeDest.destinations,
        onDestinationSelected: onDestinationSelected,
        bottomPlayer: bottomPlayer,
        playlistDrawer: playlistDrawer,
      );
"""
    first_new = """      return AdaptiveScaffold(
        body: body,
        currentIndex: currentIndex,
        destinations: activeDest.destinations,
        onDestinationSelected: onDestinationSelected,
        bottomPlayer: bottomPlayer,
        playlistDrawer: playlistDrawer,
        onClosePlaylistDrawer:
            ref.read(playerStateProvider.notifier).closePlaylistDrawer,
      );
"""
    text = replace_once(text, first, first_new, "ShellLayout large AdaptiveScaffold")
    second = """      child: AdaptiveScaffold(
        body: body,
        currentIndex: currentIndex,
        destinations: activeDest.destinations,
        onDestinationSelected: onDestinationSelected,
        bottomPlayer: bottomPlayer,
        playlistDrawer: playlistDrawer,
      ),
"""
    second_new = """      child: AdaptiveScaffold(
        body: body,
        currentIndex: currentIndex,
        destinations: activeDest.destinations,
        onDestinationSelected: onDestinationSelected,
        bottomPlayer: bottomPlayer,
        playlistDrawer: playlistDrawer,
        onClosePlaylistDrawer:
            ref.read(playerStateProvider.notifier).closePlaylistDrawer,
      ),
"""
    text = replace_once(text, second, second_new, "ShellLayout mobile AdaptiveScaffold")
    write(path, text)


def patch_manifest_and_banner() -> None:
    path = "android/app/src/main/AndroidManifest.xml"
    text = read(path)
    text = text.replace(
        'android:banner="@mipmap/ic_launcher"',
        'android:banner="@drawable/tv_banner"',
    )
    write(path, text)

    source = ROOT / "tool/tv_banner.b64"
    target = ROOT / "android/app/src/main/res/drawable-nodpi/tv_banner.png"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(base64.b64decode(source.read_text(encoding="ascii")))


def main() -> None:
    patch_app_config()
    patch_responsive()
    patch_tv_focusable()
    patch_song_list_tile()
    patch_playlist_card()
    patch_playlist_list_item()
    patch_playlists_page()
    patch_playlist_detail()
    patch_adaptive_scaffold()
    patch_shell_layout()
    patch_manifest_and_banner()
    print("TV round-one patch applied")


if __name__ == "__main__":
    main()
