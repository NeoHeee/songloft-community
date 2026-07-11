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

path.write_text(text, encoding='utf-8')
print('TV round-two helper anchors fixed')
