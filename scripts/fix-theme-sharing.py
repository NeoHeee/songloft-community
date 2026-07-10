from pathlib import Path

path = Path('lib/features/settings/presentation/widgets/theme_pack_manager.dart')
text = path.read_text(encoding='utf-8')

text = text.replace("import 'dart:typed_data';\n", '', 1)

old_switch = '''    switch (action) {
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
new_switch = '''    switch (action) {
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
if old_switch not in text:
    raise SystemExit('theme action switch target not found')
text = text.replace(old_switch, new_switch, 1)

old_dialog = '''      final confirmed = await showDialog<bool>(
        context: context,
'''
new_dialog = '''      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
'''
if old_dialog not in text:
    raise SystemExit('theme import preview target not found')
text = text.replace(old_dialog, new_dialog, 1)

path.write_text(text, encoding='utf-8')
