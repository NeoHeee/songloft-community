from pathlib import Path

path = Path(__file__).with_name('apply_tv_round3.py')
text = path.read_text(encoding='utf-8')

old = '''    def patch_tile(block: str, label: str) -> str:
        old = """          onTap: () => _onSongTap(song, index),
          onLongPress: () {
"""
        new = """          focusNode: AppConfig.isTvMode ? _focusNodeForSong(song) : null,
          autofocus: AppConfig.isTvMode &&
              (_lastFocusedSongKey == null
                  ? index == 0
                  : _lastFocusedSongKey == _songFocusKey(song)),
          onFocusChange: AppConfig.isTvMode
              ? (hasFocus) {
                  if (hasFocus) {
                    _lastFocusedSongKey = _songFocusKey(song);
                  }
                }
              : null,
          onTap: () => _onSongTap(song, index),
          onPlayNext: () => _queueSongNext(song),
          onAddToQueue: () => _addSongToQueue(song),
          onLongPress: () {
"""
        if old not in block:
            raise RuntimeError(f"missing patch anchor: {label}")
        return block.replace(old, new, 1)
'''

new = '''    def patch_tile(block: str, label: str) -> str:
        marker = "onTap: () => _onSongTap(song, index),\\n"
        pos = block.find(marker)
        if pos < 0:
            raise RuntimeError(f"missing patch anchor: {label}")
        line_start = block.rfind("\\n", 0, pos) + 1
        indent = block[line_start:pos]
        old = (
            f"{indent}onTap: () => _onSongTap(song, index),\\n"
            f"{indent}onLongPress: () {{\\n"
        )
        new = (
            f"{indent}focusNode: AppConfig.isTvMode ? _focusNodeForSong(song) : null,\\n"
            f"{indent}autofocus: AppConfig.isTvMode &&\\n"
            f"{indent}    (_lastFocusedSongKey == null\\n"
            f"{indent}        ? index == 0\\n"
            f"{indent}        : _lastFocusedSongKey == _songFocusKey(song)),\\n"
            f"{indent}onFocusChange: AppConfig.isTvMode\\n"
            f"{indent}    ? (hasFocus) {{\\n"
            f"{indent}        if (hasFocus) {{\\n"
            f"{indent}          _lastFocusedSongKey = _songFocusKey(song);\\n"
            f"{indent}        }}\\n"
            f"{indent}      }}\\n"
            f"{indent}    : null,\\n"
            f"{indent}onTap: () => _onSongTap(song, index),\\n"
            f"{indent}onPlayNext: () => _queueSongNext(song),\\n"
            f"{indent}onAddToQueue: () => _addSongToQueue(song),\\n"
            f"{indent}onLongPress: () {{\\n"
        )
        if old not in block:
            raise RuntimeError(f"missing adjacent long-press anchor: {label}")
        return block.replace(old, new, 1)
'''

if old not in text:
    raise RuntimeError('unable to locate Library tile patch helper')

path.write_text(text.replace(old, new, 1), encoding='utf-8')
print('TV round-three helper anchors fixed')
