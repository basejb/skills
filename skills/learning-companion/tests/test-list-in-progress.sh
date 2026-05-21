#!/bin/bash
set -euo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/scripts/list-in-progress.sh"
TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$TEST_TMPDIR"' EXIT
export LEARNING_NOTES_DIR="$TEST_TMPDIR"

PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; PASS=$((PASS+1)); else echo "FAIL: $1"; FAIL=$((FAIL+1)); fi }

# Case 1: INDEX.md 없음 → 빈 출력, exit 0
OUT=$("$SCRIPT")
check "case1-empty-no-index" "[ -z '$OUT' ]"

# Case 2: 항목 2개 있음
cat > "$TEST_TMPDIR/INDEX.md" <<'EOF'
# Learning Index

## In Progress
- 2026-05-21 [Agents](2026-05-21-agents.md) — tags: [ai-agent]
- 2026-05-20 [MCP](2026-05-20-mcp.md) — tags: [protocol]

## Completed
- 2026-05-19 [Old](2026-05-19-old.md) — completed 2026-05-20

## Backlog
EOF

OUT=$("$SCRIPT")
check "case2-shows-agents" "echo '$OUT' | grep -q 'Agents'"
check "case2-shows-mcp" "echo '$OUT' | grep -q 'MCP'"
check "case2-hides-completed" "! echo '$OUT' | grep -q 'Old'"

echo
echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ]
