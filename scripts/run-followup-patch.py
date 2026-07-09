from pathlib import Path
from textwrap import dedent


def leading_spaces(value: str) -> int:
    return len(value) - len(value.lstrip(" "))


workflow = Path(".github/workflows/apply-playlist-mobile-nav-followup.yml")
text = workflow.read_text(encoding="utf-8")
marker = "          python - <<'PY'\n"
start = text.index(marker) + len(marker)
end = text.index("\n          PY\n", start)
lines = dedent(text[start:end]).splitlines()

index = 0
while index < len(lines):
    line = lines[index]
    marker_index = line.find('"""')
    if marker_index < 0:
        index += 1
        continue

    first_content = line[marker_index + 3 :]
    if not first_content or '"""' in first_content:
        index += 1
        continue

    close_index = index + 1
    while close_index < len(lines) and '"""' not in lines[close_index]:
        close_index += 1
    if close_index >= len(lines):
        raise SystemExit(f"Unclosed triple-quoted block at patch line {index + 1}")

    content_indices = [
        current
        for current in range(index + 1, close_index)
        if lines[current].strip()
    ]
    if content_indices:
        base_indent = leading_spaces(first_content)
        first_code = first_content.strip()
        nested = first_code.endswith(("{", "[", "("))
        target_minimum = base_indent + (2 if nested else 0)
        current_minimum = min(
            leading_spaces(lines[current]) for current in content_indices
        )
        delta = max(0, target_minimum - current_minimum)
        if delta:
            for current in content_indices:
                lines[current] = (" " * delta) + lines[current]

    index = close_index + 1

script = "\n".join(lines) + "\n"
script = script.replace(
    "                          onSelectionChanged: (selected) {\n"
    "                              setState(() {\n"
    "                                _selectedType = selected.first;\n"
    "                              });\n"
    "                            },",
    "                          onSelectionChanged: (selected) {\n"
    "                            setState(() {\n"
    "                              _selectedType = selected.first;\n"
    "                            });\n"
    "                          },",
)
script = script.replace(
    "                          onSelectionChanged: (selected) {\n"
    "                              _changeSelectedType(selected.first);\n"
    "                            },",
    "                          onSelectionChanged: (selected) {\n"
    "                            _changeSelectedType(selected.first);\n"
    "                          },",
)

compiled = compile(script, "<playlist-mobile-nav-followup>", "exec")
exec(compiled, {"__name__": "__main__"})
