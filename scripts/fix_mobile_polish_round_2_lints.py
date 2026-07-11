from pathlib import Path


path = Path("lib/features/player/presentation/queue_page.dart")
text = path.read_text(encoding="utf-8")
old = "return '约 ${duration.inHours} 小时 ${minutes} 分钟';"
new = "return '约 ${duration.inHours} 小时 $minutes 分钟';"
if old not in text:
    raise RuntimeError("Queue duration interpolation marker not found")
path.write_text(text.replace(old, new, 1), encoding="utf-8")
print("Fixed queue duration interpolation lint")
