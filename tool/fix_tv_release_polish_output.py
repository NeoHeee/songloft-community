from pathlib import Path

root = Path(__file__).resolve().parents[1]

for relative in [
    'lib/features/playlist/presentation/playlists_page.dart',
    'lib/features/playlist/presentation/playlist_detail_page.dart',
]:
    path = root / relative
    text = path.read_text(encoding='utf-8')
    marker = "import 'package:flutter/material.dart';\n"
    services = "import 'package:flutter/services.dart';\n"
    if services not in text:
        if marker not in text:
            raise RuntimeError(f'missing material import in {relative}')
        text = text.replace(marker, marker + services, 1)
    path.write_text(text, encoding='utf-8')

player_path = root / 'lib/features/player/presentation/widgets/tv_player.dart'
player = player_path.read_text(encoding='utf-8')
player = player.replace('  final bool autofocus;\n', '', 1)
player = player.replace('    this.autofocus = false,\n', '', 1)
player = player.replace('            autofocus: widget.autofocus,\n', '', 1)
player_path.write_text(player, encoding='utf-8')

print('TV release polish output cleaned')
