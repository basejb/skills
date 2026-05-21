#!/bin/bash
set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/scripts/update-index.sh"
TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$TEST_TMPDIR"' EXIT
export LEARNING_NOTES_DIR="$TEST_TMPDIR"

PASS=0
FAIL=0
check() {
  if eval "$2"; then echo "PASS: $1"; PASS=$((PASS+1)); else echo "FAIL: $1"; FAIL=$((FAIL+1)); fi
}

# 준비: 가짜 노트 파일
NOTE="$TEST_TMPDIR/2026-05-21-agents.md"
cat > "$NOTE" <<EOF
---
title: Building Effective Agents
source: https://example.com
captured: 2026-05-21
status: in-progress
tags: [ai-agent]
next: []
---
EOF

# Case 1: in-progress 추가 → INDEX 생성됨, 항목 포함
"$SCRIPT" --add-in-progress "$NOTE"
INDEX="$TEST_TMPDIR/INDEX.md"
check "case1-index-created" "[ -f '$INDEX' ]"
check "case1-has-in-progress-header" "grep -q '^## In Progress$' '$INDEX'"
check "case1-has-entry" "grep -q 'Building Effective Agents' '$INDEX'"
check "case1-has-link" "grep -q '2026-05-21-agents.md' '$INDEX'"

# Case 2: 같은 항목 다시 추가 → idempotent (중복 라인 X)
"$SCRIPT" --add-in-progress "$NOTE"
COUNT=$(grep -c 'Building Effective Agents' "$INDEX")
check "case2-idempotent" "[ $COUNT -eq 1 ]"

# Case 3: completed로 이동
"$SCRIPT" --mark-completed "2026-05-21-agents"
check "case3-moved-to-completed" "awk '/^## Completed$/{found=1} found && /Building Effective Agents/{found=2} END{exit found!=2}' '$INDEX'"
check "case3-removed-from-in-progress" "! awk '/^## In Progress$/{f=1; next} /^## /{f=0} f && /Building Effective Agents/{found=1} END{exit !found}' '$INDEX'"

# Case 4: backlog 추가
"$SCRIPT" --add-backlog "MCP Protocol Spec" --from "2026-05-21-agents"
check "case4-has-backlog-header" "grep -q '^## Backlog' '$INDEX'"
check "case4-has-backlog-entry" "grep -q 'MCP Protocol Spec' '$INDEX'"
check "case4-has-from-attribution" "grep -q 'from 2026-05-21-agents' '$INDEX'"

# Case 5: 같은 backlog 다시 → idempotent
"$SCRIPT" --add-backlog "MCP Protocol Spec" --from "2026-05-21-agents"
COUNT=$(grep -c 'MCP Protocol Spec' "$INDEX")
check "case5-backlog-idempotent" "[ $COUNT -eq 1 ]"

# Case 6: title with YAML quotes (as produced by current new-note.sh)
NOTE2="$TEST_TMPDIR/2026-05-22-quoted.md"
cat > "$NOTE2" <<EOF
---
title: "Quoted Title: With Colon"
source: "https://example.com/q"
captured: 2026-05-22
status: in-progress
tags: [quoted-test]
next: []
---
EOF
"$SCRIPT" --add-in-progress "$NOTE2"
check "case6-quoted-title-parsed-without-quotes" "grep -q '\[Quoted Title: With Colon\]' '$INDEX'"
check "case6-no-literal-quotes-in-entry" "! grep -q '\[\"Quoted Title' '$INDEX'"

# Case 7: --add-backlog without --from → exit 2
set +e
"$SCRIPT" --add-backlog "Orphan" >/dev/null 2>&1
RC=$?
set -e
check "case7-add-backlog-requires-from" "[ $RC -eq 2 ]"

echo
echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ]
