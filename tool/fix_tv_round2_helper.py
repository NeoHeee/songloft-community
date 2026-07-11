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

path.write_text(text.replace(old, new, 1), encoding='utf-8')
print('TV round-two helper anchors fixed')
