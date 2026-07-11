from pathlib import Path

path = Path(__file__).with_name('apply_tv_icon_polish.py')
text = path.read_text(encoding='utf-8')

old_block = '''    text = replace_once(
        text,
        ''' + "'''" + '''                 (context, index) => _RegistryPluginItem(
                   entry: plugins[index],
''' + "'''" + ''',
        ''' + "'''" + '''                 (context, index) => _RegistryPluginItem(
                   entry: plugins[index],
                   autofocus: AppConfig.isTvMode && index == 0,
''' + "'''" + ''',
        'plugin item autofocus',
    )

'''

if old_block not in text:
    raise RuntimeError('unable to locate redundant plugin autofocus patch')
text = text.replace(old_block, '', 1)

old_line = "                  autofocus: AppConfig.isTvMode && index == 0,\n"
if old_line not in text:
    raise RuntimeError('unable to locate old-list autofocus line')
text = text.replace(old_line, '', 1)

path.write_text(text, encoding='utf-8')
print('TV icon polish helper fixed')
