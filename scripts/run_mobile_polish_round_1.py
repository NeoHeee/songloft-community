from pathlib import Path
import re
import runpy


script = Path('scripts/apply_mobile_polish_round_1.py')
text = script.read_text(encoding='utf-8')
replacement = '''def main() -> None:
    memory = Path("lib/core/storage/mobile_tab_memory.dart")
    memory.write_text(
        """/// 进程内保存手机端一级页面的临时现场。
///
/// 仅用于标签页切换时恢复滚动、搜索和筛选，不写入磁盘。
class MobileTabMemory {
  MobileTabMemory._();

  static double homeScrollOffset = 0;
  static double libraryScrollOffset = 0;
  static double playlistsScrollOffset = 0;

  static String librarySearch = '';
  static String playlistsSearch = '';
  static String? playlistType;
}
""",
        encoding="utf-8",
    )
    patch_home()
'''
text, count = re.subn(
    r'def main\(\) -> None:\n.*?    patch_home\(\)\n',
    replacement,
    text,
    count=1,
    flags=re.S,
)
if count != 1:
    raise RuntimeError(f'Unable to repair patch script, matches: {count}')
script.write_text(text, encoding='utf-8')
runpy.run_path(str(script), run_name='__main__')

player = Path('lib/features/player/presentation/widgets/mobile_player.dart')
player_text = player.read_text(encoding='utf-8')
old = '''          ],
        ),
      ),
    );
  }

  /// 构建页面指示器（小圆点）
'''
new = '''          ],
        ),
      ),
    ),
  );
  }

  /// 构建页面指示器（小圆点）
'''
if old not in player_text:
    raise RuntimeError('Unable to close mobile player gesture wrapper')
player.write_text(player_text.replace(old, new, 1), encoding='utf-8')
