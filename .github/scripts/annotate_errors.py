"""Превращает ошибки xcodebuild в аннотации GitHub Actions.

Аннотации видны на странице запуска и через публичный API — без скачивания логов.
Использование: python3 annotate_errors.py xcodebuild.log
"""
import os
import re
import sys

LOCATED = re.compile(r"^(/[^:]+):(\d+)(?::(\d+))?: (?:fatal )?error: (.*)$")
GENERIC = re.compile(r"\berror: (.*)$", re.IGNORECASE)

workspace = os.environ.get("GITHUB_WORKSPACE", "") + "/"
seen = set()
located, generic = [], []

with open(sys.argv[1], errors="ignore") as log:
    for raw in log:
        line = raw.strip()
        m = LOCATED.match(line)
        if m:
            path, row, col, msg = m.groups()
            key = (path, row, msg)
            if key not in seen:
                seen.add(key)
                located.append((path.replace(workspace, ""), row, col or "1", msg))
            continue
        g = GENERIC.search(line)
        if g and g.group(1) not in seen:
            seen.add(g.group(1))
            generic.append(g.group(1))

print(f"Ошибок с указанием файла: {len(located)}, прочих: {len(generic)}")
for path, row, col, msg in located:
    print(f"::error file={path},line={row},col={col}::{msg}")
# Прочие — только если нет ошибок с файлами (обычно это их дубли).
if not located:
    for msg in generic[:20]:
        print(f"::error::{msg}")
