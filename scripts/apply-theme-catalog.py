from pathlib import Path

manager = Path('lib/features/settings/presentation/widgets/theme_pack_manager.dart')
text = manager.read_text(encoding='utf-8')

import_target = "import '../../../../shared/utils/responsive_snackbar.dart';\n"
import_replacement = (
    "import '../../../../shared/utils/responsive_snackbar.dart';\n"
    "import 'theme_catalog_dialog.dart';\n"
)
if "import 'theme_catalog_dialog.dart';" not in text:
    if import_target not in text:
        raise SystemExit('theme manager import target not found')
    text = text.replace(import_target, import_replacement, 1)

button_target = '''            children: [
              FilledButton.icon(
                onPressed: () => _importThemePack(context, ref),
'''
button_replacement = '''            children: [
              FilledButton.tonalIcon(
                onPressed: () => showThemeCatalogDialog(context),
                icon: const Icon(Icons.storefront_rounded),
                label: const Text('在线主题'),
              ),
              FilledButton.icon(
                onPressed: () => _importThemePack(context, ref),
'''
if "label: const Text('在线主题')" not in text:
    if button_target not in text:
        raise SystemExit('theme manager button target not found')
    text = text.replace(button_target, button_replacement, 1)
manager.write_text(text, encoding='utf-8')

catalog_dialog = Path(
    'lib/features/settings/presentation/widgets/theme_catalog_dialog.dart'
)
text = catalog_dialog.read_text(encoding='utf-8')
text = text.replace(
    'Future<void> showThemeCatalogDialog(BuildContext context) {\n'
    '  return showDialog<void>(\n',
    'Future<void> showThemeCatalogDialog(BuildContext context) async {\n'
    '  await showDialog<void>(\n',
    1,
)
text = text.replace(
    '        height: compact ? size.height : size.height.clamp(620, 820),',
    '        height:\n'
    '            compact\n'
    '                ? size.height\n'
    '                : size.height.clamp(620.0, 820.0).toDouble(),',
    1,
)
watch_target = '''  Widget build(BuildContext context) {
    final catalogState = ref.watch(themeCatalogProvider);
'''
watch_replacement = '''  Widget build(BuildContext context) {
    final catalogState = ref.watch(themeCatalogProvider);
    ref.watch(themePackProvider);
'''
if watch_target not in text:
    raise SystemExit('catalog dialog provider watch target not found')
text = text.replace(watch_target, watch_replacement, 1)
text = text.replace(
    '    for (final pack in ref.watch(themePackProvider).customPacks) {',
    '    for (final pack in ref.read(themePackProvider).customPacks) {',
    1,
)
catalog_dialog.write_text(text, encoding='utf-8')

pubspec = Path('pubspec.yaml')
text = pubspec.read_text(encoding='utf-8')
asset_target = '''  assets:
    - assets/icons/app_icon.png
    - windows/runner/resources/app_icon.ico
'''
asset_replacement = '''  assets:
    - assets/icons/app_icon.png
    - assets/theme_catalog/catalog.json
    - assets/theme_catalog/themes/
    - windows/runner/resources/app_icon.ico
'''
if 'assets/theme_catalog/catalog.json' not in text:
    if asset_target not in text:
        raise SystemExit('pubspec asset target not found')
    text = text.replace(asset_target, asset_replacement, 1)
pubspec.write_text(text, encoding='utf-8')

workflow = Path('.github/workflows/ui-redesign-check.yml')
text = workflow.read_text(encoding='utf-8')
text = text.replace(
    '      - name: Run theme pack tests\n'
    '        run: flutter test test/core/theme/theme_pack_test.dart\n',
    '      - name: Run theme system tests\n'
    '        run: flutter test test/core/theme\n',
    1,
)
workflow.write_text(text, encoding='utf-8')
