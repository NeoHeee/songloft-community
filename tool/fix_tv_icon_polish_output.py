from pathlib import Path

path = (
    Path(__file__).resolve().parents[1]
    / 'lib/features/jsplugin/presentation/widgets/plugin_registry.dart'
)
text = path.read_text(encoding='utf-8')
text = text.replace("import 'package:flutter_svg/flutter_svg.dart';\n", '', 1)

marker = '  Widget _buildIcon(RegistryPluginEntry entry, ThemeData theme) {'
if marker in text:
    start = text.index(marker)
    end = text.index('  Widget _buildAction(', start)
    text = text[:start] + text[end:]

path.write_text(text, encoding='utf-8')
print('TV icon polish output cleaned')
