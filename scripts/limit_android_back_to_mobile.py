from pathlib import Path


path = Path("lib/shared/layouts/shell_layout.dart")
text = path.read_text(encoding="utf-8")

marker = "    final routerCanPop = GoRouter.of(context).canPop();\n"
mobile_only = """    if (screenType != ScreenType.mobile) {
      return AdaptiveScaffold(
        body: body,
        currentIndex: currentIndex,
        destinations: activeDest.destinations,
        onDestinationSelected: onDestinationSelected,
        bottomPlayer: bottomPlayer,
        playlistDrawer: playlistDrawer,
      );
    }

"""

if "if (screenType != ScreenType.mobile)" not in text:
    if marker not in text:
        raise RuntimeError("Mobile back navigation marker not found")
    text = text.replace(marker, mobile_only + marker, 1)
    path.write_text(text, encoding="utf-8")
    print("Restricted Android back navigation handling to mobile screens")
else:
    print("Mobile-only restriction already applied")
