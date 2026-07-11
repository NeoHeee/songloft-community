from pathlib import Path

path = Path(__file__).with_name('apply_tv_round2.py')
text = path.read_text(encoding='utf-8')

old = '''    text = replace_once(
        text,
        "                 child: Row(\\n                   mainAxisAlignment: MainAxisAlignment.center,",
        "                 child: FittedBox(\\n"
        "                   fit: BoxFit.scaleDown,\\n"
        "                   child: Row(\\n"
        "                     mainAxisAlignment: MainAxisAlignment.center,",
        "TvPlayer controls FittedBox open",
    )
    text = replace_once(
        text,
        "           ],\\n         ),\\n       ),\\n     );\\n   }\\n\\n   /// 播放/暂停按钮",
        "           ],\\n"
        "                   ),\\n"
        "                 ),\\n"
        "       ),\\n"
        "     );\\n"
        "   }\\n\\n"
        "   /// 播放/暂停按钮",
        "TvPlayer controls FittedBox close",
    )
'''

new = '''    text = replace_once(
        text,
        "      child: Row(\\n        mainAxisAlignment: MainAxisAlignment.center,",
        "      child: FittedBox(\\n"
        "        fit: BoxFit.scaleDown,\\n"
        "        child: Row(\\n"
        "          mainAxisAlignment: MainAxisAlignment.center,",
        "TvPlayer controls FittedBox open",
    )
    text = replace_once(
        text,
        "        ],\\n      ),\\n    );\\n  }\\n\\n  /// 播放/暂停按钮",
        "          ],\\n"
        "        ),\\n"
        "      ),\\n"
        "    );\\n"
        "  }\\n\\n"
        "  /// 播放/暂停按钮",
        "TvPlayer controls FittedBox close",
    )
'''

if old not in text:
    raise RuntimeError('unable to locate FittedBox helper block')
text = text.replace(old, new, 1)

old_focus = '''        "                 (buttonContext) => _TvPlayerControlButton(\\n"
        "                   icon: _getPlayModeIcon(state.playMode),",
        "                 (buttonContext) => _TvPlayerControlButton(\\n"
        "                   icon: _getPlayModeIcon(state.playMode),\\n"
        "                   focusNode: _playModeButtonFocusNode,",
'''
new_focus = '''        "                (buttonContext) => _TvPlayerControlButton(\\n"
        "                  icon: _getPlayModeIcon(state.playMode),",
        "                (buttonContext) => _TvPlayerControlButton(\\n"
        "                  icon: _getPlayModeIcon(state.playMode),\\n"
        "                  focusNode: _playModeButtonFocusNode,",
'''
if old_focus not in text:
    raise RuntimeError('unable to locate play-mode focus helper block')
text = text.replace(old_focus, new_focus, 1)

old_mode = '''        "                             (itemContext) => TvFocusable(\\n"
        "                               onSelect: () => onPlayModeChanged(mode),",
        "                             (itemContext) => TvFocusable(\\n"
        "                               autofocus: mode == playMode,\\n"
        "                               onSelect: () => onPlayModeChanged(mode),",
'''
new_mode = '''        "                            (itemContext) => TvFocusable(\\n"
        "                              onSelect: () => onPlayModeChanged(mode),",
        "                            (itemContext) => TvFocusable(\\n"
        "                              autofocus: mode == playMode,\\n"
        "                              onSelect: () => onPlayModeChanged(mode),",
'''
if old_mode not in text:
    raise RuntimeError('unable to locate selected play-mode helper block')
text = text.replace(old_mode, new_mode, 1)

text = text.replace(
    'text.index("               // 封面\\n", text.index("class TvMiniPlayer"))',
    'text.index("              // 封面\\n", text.index("class TvMiniPlayer"))',
    1,
)
text = text.replace(
    'text.index("               // 播放控制\\n", mini_start)',
    'text.index("              // 播放控制\\n", mini_start)',
    1,
)

path.write_text(text, encoding='utf-8')
print('TV round-two helper anchors fixed')
