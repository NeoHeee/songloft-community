from pathlib import Path

path = Path(__file__).with_name('apply_tv_release_polish.py')
text = path.read_text(encoding='utf-8')

replacements = {
    "final target = (index + delta).clamp(0, _sortablePlaylists.length - 1);":
        "final target = (index + delta)\n        .clamp(0, _sortablePlaylists.length - 1)\n        .toInt();",
    "final target = (index + delta).clamp(0, _sortableSongs.length - 1);":
        "final target = (index + delta)\n        .clamp(0, _sortableSongs.length - 1)\n        .toInt();",
}

for old, new in replacements.items():
    if old not in text:
        raise RuntimeError(f'missing helper type anchor: {old}')
    text = text.replace(old, new, 1)

path.write_text(text, encoding='utf-8')
print('TV release polish helper types fixed')
