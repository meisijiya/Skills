#!/usr/bin/env bash
# scripts/check-doc-drift.sh
#
# Compare current skill-count claims in README.md, AGENTS.md, and
# skills/extra/README.md against .claude-plugin/marketplace.json.
# CHANGELOG.md is intentionally not checked; historical counts are valid there.
#
# Exits 0 when all checked claims match the marketplace, 1 on drift.

set -euo pipefail

python3 - <<'PY'
import json
import os
import re
import sys

manifest = ".claude-plugin/marketplace.json"
files = ["README.md", "AGENTS.md", "skills/extra/README.md"]

if not os.path.isfile(manifest):
    print(f"FAIL: {manifest} not found", file=sys.stderr)
    sys.exit(1)

with open(manifest, encoding="utf-8") as f:
    marketplace = json.load(f)

plugins = marketplace.get("plugins", [])
groups = {
    plugin["name"].removeprefix("meisijiya-"): len(plugin.get("skills", []))
    for plugin in plugins
}
total = sum(groups.values())
print(f"Marketplace counts: total={total}")
for group, count in groups.items():
    print(f"  {group}: {count}")
print()

issues = []

def line_no(text, position):
    return text.count("\n", 0, position) + 1

def add_issue(path, text, match, expected, label):
    actual = int(match.group(1))
    if actual != expected:
        issues.append(
            f"{path}:{line_no(text, match.start())}: {label} found {actual}, expected {expected}"
        )

for path in files:
    if not os.path.isfile(path):
        continue
    with open(path, encoding="utf-8") as f:
        text = f.read()

    # These files are current-state documents. Keep all content visible so a
    # stale number cannot hide in a section that happens to use a version header.
    masked = text

    # Total claims are only standalone repository totals, not per-group counts,
    # plugin counts, directory listings, or historical notes in the current-state
    # section. The explicit core + extra split is checked separately below.
    total_patterns = [
        re.compile(r"(?:共|总数|total)\s*[:：]?\s*(\d+)\s*(?:个\s*)?(?:skill|skills|SKILL\.md)", re.I),
        re.compile(r"\b(\d+)\s*(?:个\s*)?SKILL\.md\s*(?:总数|total)\b", re.I),
    ]
    for pattern in total_patterns:
        for match in pattern.finditer(masked):
            add_issue(path, masked, match, total, "total skill count")

    # Core/extra split claims: `9 + 33`, `9 + 33 个`, `9 个` and `33 个` joined by
    # `+` through any inline text (e.g. `(9 个) + ... (33 个)`).
    adjacent_split = re.compile(r"\b(\d+)\s*\+\s*(\d+)(?:\s*个)?")
    paren_split = re.compile(
        r"\(\s*(\d+)\s*个\s*\)\s*\+\s*`?[^()]*`?\s*\(\s*(\d+)\s*个",
        re.I,
    )
    expected_left, expected_right = groups["core"], total - groups["core"]

    def check_split(match, label):
        left, right = int(match.group(1)), int(match.group(2))
        if (left, right) == (expected_left, expected_right):
            return
        if left in (expected_left, expected_right) or right in (expected_left, expected_right):
            issues.append(
                f"{path}:{line_no(masked, match.start())}: split {left} + {right} does not match core {expected_left} + extra {expected_right}"
            )
        else:
            issues.append(
                f"{path}:{line_no(masked, match.start())}: split {left} + {right} ({label}) does not match core {expected_left} + extra {expected_right}"
            )

    for match in paren_split.finditer(masked):
        check_split(match, "paren form")
    for match in adjacent_split.finditer(masked):
        check_split(match, "adjacent form")

    # Named group counts: `core: 9`, `domain group (11)`, `security (9)`, etc.
    for group, expected in groups.items():
        escaped = re.escape(group)
        patterns = [
            re.compile(rf"\b{escaped}\s*:\s*(\d+)\b", re.I),
            re.compile(rf"\b{escaped}(?:\s+group)?\s*[(:]\s*(\d+)\s*(?:个)?\s*[)]?", re.I),
        ]
        for pattern in patterns:
            for match in pattern.finditer(masked):
                add_issue(path, masked, match, expected, f"{group} group count")

if issues:
    print("Drift detected:")
    for issue in issues:
        print(f"  - {issue}")
    sys.exit(1)

print("OK doc-vs-marketplace in sync")
PY
