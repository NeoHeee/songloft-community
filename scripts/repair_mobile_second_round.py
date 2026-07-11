from pathlib import Path


player = Path("lib/features/player/presentation/widgets/mobile_player.dart")
text = player.read_text(encoding="utf-8")

text = text.replace(
    "    final dragProgress = (_dragOffset / (size.height * 0.35)).clamp(0.0, 1.0);\n",
    "    final dragProgress =\n"
    "        (_dragOffset / (size.height * 0.35)).clamp(0.0, 1.0).toDouble();\n",
    1,
)

text = text.replace(
    "          transform:\n"
    "              Matrix4.identity()\n"
    "                ..translate(0.0, _dragOffset)\n"
    "                ..scale(dragScale, dragScale),\n",
    "          transform:\n"
    "              (Matrix4.identity()\n"
    "                ..setEntry(0, 0, dragScale)\n"
    "                ..setEntry(1, 1, dragScale)\n"
    "                ..setTranslationRaw(0, _dragOffset, 0)),\n",
    1,
)
player.write_text(text, encoding="utf-8")

queue = Path("lib/features/player/presentation/queue_page.dart")
text = queue.read_text(encoding="utf-8")
text = text.replace(
    "      final clampedTarget = target.clamp(0.0, position.maxScrollExtent);\n",
    "      final clampedTarget =\n"
    "          target.clamp(0.0, position.maxScrollExtent).toDouble();\n",
    1,
)
queue.write_text(text, encoding="utf-8")

print("Repaired mobile second round analyzer compatibility")
