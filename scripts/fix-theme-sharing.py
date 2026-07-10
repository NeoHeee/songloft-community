from pathlib import Path

path = Path('lib/features/settings/presentation/widgets/theme_pack_manager.dart')
text = path.read_text(encoding='utf-8')
old = '''    switch (action) {
      case _ThemePackAction.details:
        await showDialog<void>(
          context: context,
          builder: (_) => _ThemePackDetailsDialog(pack: pack),
        );
      case _ThemePackAction.copyJson:
        await _copyThemeJson(context, pack);
      case _ThemePackAction.export:
        await _exportThemePack(context, pack);
      case _ThemePackAction.delete:
        await _confirmDelete(context, ref, pack);
    }
'''
new = '''    switch (action) {
      case _ThemePackAction.details:
        await showDialog<void>(
          context: context,
          builder: (_) => _ThemePackDetailsDialog(pack: pack),
        );
        break;
      case _ThemePackAction.copyJson:
        await _copyThemeJson(context, pack);
        break;
      case _ThemePackAction.export:
        await _exportThemePack(context, pack);
        break;
      case _ThemePackAction.delete:
        await _confirmDelete(context, ref, pack);
        break;
    }
'''
if old not in text:
    raise SystemExit('theme action switch target not found')
path.write_text(text.replace(old, new, 1), encoding='utf-8')
