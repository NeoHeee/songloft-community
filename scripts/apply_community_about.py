from pathlib import Path


path = Path("lib/features/settings/presentation/settings_page.dart")
text = path.read_text(encoding="utf-8")

text = text.replace(
    "import 'widgets/frontend_upgrade_dialog.dart';\n",
    "",
    1,
)

old_items = """          _buildServerVersionTile(),
          if (!AppConfig.isEmbedded) ...[
            const Divider(height: 1),
            _buildFrontendUpdateTile(),
          ],
          const Divider(height: 1),
"""
new_items = """          _buildServerVersionTile(),
          const Divider(height: 1),
"""
if old_items in text:
    text = text.replace(old_items, new_items, 1)
elif "_buildFrontendUpdateTile()," in text:
    raise RuntimeError("Unexpected client update tile layout")

method_start = text.find("  Widget _buildFrontendUpdateTile() {")
if method_start >= 0:
    method_end = text.find("  Widget _buildHlsProxyTile() {", method_start)
    if method_end < 0:
        raise RuntimeError("Client update method end marker not found")
    text = text[:method_start] + text[method_end:]

old_version = "      applicationVersion: version,\n"
new_version = "      applicationVersion: '$version · 社区魔改版',\n"
if old_version in text:
    text = text.replace(old_version, new_version, 1)
elif "社区魔改版" not in text:
    raise RuntimeError("About dialog version line not found")

path.write_text(text, encoding="utf-8")
print("Applied community edition label and removed client update entry")
