#!/bin/bash
set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/scripts/new-note.sh"
TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$TEST_TMPDIR"' EXIT

export LEARNING_NOTES_DIR="$TEST_TMPDIR/notes"

PASS=0
FAIL=0

check() {
  local name="$1"
  local cond="$2"
  if eval "$cond"; then
    echo "PASS: $name"
    PASS=$((PASS+1))
  else
    echo "FAIL: $name (cond: $cond)"
    FAIL=$((FAIL+1))
  fi
}

# Case 1: 기본 생성
OUT=$("$SCRIPT" --title "Building Effective Agents" --source "https://example.com/x" --slug "agents")
EXPECTED_PATH="$LEARNING_NOTES_DIR/$(date +%Y-%m-%d)-agents.md"
check "case1-stdout-prints-path" "[ '$OUT' = '$EXPECTED_PATH' ]"
check "case1-file-exists" "[ -f '$EXPECTED_PATH' ]"
check "case1-has-frontmatter-title" "grep -q '^title: Building Effective Agents$' '$EXPECTED_PATH'"
check "case1-has-frontmatter-source" "grep -q '^source: https://example.com/x$' '$EXPECTED_PATH'"
check "case1-has-frontmatter-status" "grep -q '^status: in-progress$' '$EXPECTED_PATH'"
check "case1-has-section-source" "grep -q '^## Source$' '$EXPECTED_PATH'"
check "case1-has-section-concepts" "grep -q '^## Concepts (Feynman)$' '$EXPECTED_PATH'"
check "case1-has-section-quiz" "grep -q '^## Quiz$' '$EXPECTED_PATH'"
check "case1-has-section-reflection" "grep -q '^## Reflection (Metacognition)$' '$EXPECTED_PATH'"
check "case1-has-section-next" "grep -q '^## Next$' '$EXPECTED_PATH'"

# Case 2: 슬러그 미지정 시 title에서 자동 생성
OUT2=$("$SCRIPT" --title "MCP Protocol Spec" --source "https://example.com/mcp")
EXPECTED_PATH2="$LEARNING_NOTES_DIR/$(date +%Y-%m-%d)-mcp-protocol-spec.md"
check "case2-auto-slug-from-title" "[ '$OUT2' = '$EXPECTED_PATH2' ]"

# Case 3: 이미 존재하는 노트 → 비-0 exit
set +e
"$SCRIPT" --title "Building Effective Agents" --source "https://example.com/x" --slug "agents" >/dev/null 2>&1
RC=$?
set -e
check "case3-existing-note-fails" "[ $RC -ne 0 ]"

# Case 4: --title 누락 → 비-0 exit
set +e
"$SCRIPT" --source "https://example.com/x" --slug "no-title" >/dev/null 2>&1
RC=$?
set -e
check "case4-missing-title-fails" "[ $RC -ne 0 ]"

echo
echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ]
