#!/bin/bash
set -euo pipefail

NOTES_DIR="${LEARNING_NOTES_DIR:-$HOME/learning-notes}"
INDEX="$NOTES_DIR/INDEX.md"

ensure_index() {
  mkdir -p "$NOTES_DIR"
  if [[ ! -f "$INDEX" ]]; then
    cat > "$INDEX" <<'EOF'
# Learning Index

## In Progress

## Completed

## Backlog
EOF
  fi
  grep '^## In Progress$' "$INDEX" > /dev/null 2>&1 || echo -e "\n## In Progress" >> "$INDEX"
  grep '^## Completed$' "$INDEX" > /dev/null 2>&1 || echo -e "\n## Completed" >> "$INDEX"
  grep '^## Backlog$' "$INDEX" > /dev/null 2>&1 || echo -e "\n## Backlog" >> "$INDEX"
}

# 특정 섹션 바로 아래에 라인 삽입 (중복 시 no-op)
# $3: optional idempotent pattern - if provided, checks for this pattern instead of full line
insert_under_section() {
  local section="$1"
  local line="$2"
  local idempotent_pattern="${3:-}"

  # Check if line already exists using provided pattern or basename/title check
  if [[ -n "$idempotent_pattern" ]]; then
    if awk -v pattern="$idempotent_pattern" '/^## '"$section"'$/{f=1; next} /^## /{f=0} f && index($0, pattern)' "$INDEX" | grep -q . ; then
      return 0
    fi
  else
    if grep -q "$(echo "$line" | grep -o '[^/]*\.md')" "$INDEX" 2>/dev/null; then
      return 0
    fi
  fi

  awk -v section="## $section" -v line="$line" '
    !inserted && $0==section {print; print ""; print line; inserted=1; next}
    {print}
  ' "$INDEX" > "$INDEX.tmp" && mv "$INDEX.tmp" "$INDEX"
}

case "${1:-}" in
  --add-in-progress)
    [[ $# -ge 2 ]] || { echo "ERROR: --add-in-progress requires a note file" >&2; exit 2; }
    NOTE_FILE="$2"
    [[ -f "$NOTE_FILE" ]] || { echo "ERROR: note file not found: $NOTE_FILE" >&2; exit 2; }

    # YAML frontmatter에서 값 추출. title은 "..." 따옴표 안 또는 raw scalar 둘 다 처리.
    TITLE=$(awk '
      /^title: "/ { sub(/^title: "/, ""); sub(/"$/, ""); print; exit }
      /^title: / { sub(/^title: /, ""); print; exit }
    ' "$NOTE_FILE")
    CAPTURED=$(awk -F': ' '/^captured: /{print $2; exit}' "$NOTE_FILE")
    BASENAME=$(basename "$NOTE_FILE")
    TAGS=$(awk -F'[][]' '/^tags: /{print $2; exit}' "$NOTE_FILE")

    LINE="- $CAPTURED [$TITLE]($BASENAME) — tags: [$TAGS]"
    ensure_index
    insert_under_section "In Progress" "$LINE" "$BASENAME"
    ;;

  --mark-completed)
    [[ $# -ge 2 ]] || { echo "ERROR: --mark-completed requires a slug" >&2; exit 2; }
    SLUG="$2"
    ensure_index
    TODAY=$(date +%Y-%m-%d)

    LINE=$(awk -v slug="$SLUG" '
      /^## In Progress$/ {f=1; next}
      /^## / {f=0}
      f && index($0, slug) {print; exit}
    ' "$INDEX")
    [[ -n "$LINE" ]] || { echo "ERROR: $SLUG not in In Progress" >&2; exit 1; }

    NEW_LINE="$LINE — completed $TODAY"

    awk -v slug="$SLUG" '
      /^## In Progress$/ {f=1; print; next}
      /^## / {f=0}
      f && index($0, slug) {next}
      {print}
    ' "$INDEX" > "$INDEX.tmp" && mv "$INDEX.tmp" "$INDEX"

    insert_under_section "Completed" "$NEW_LINE"
    ;;

  --add-backlog)
    [[ $# -ge 2 ]] || { echo "ERROR: --add-backlog requires a title" >&2; exit 2; }
    TITLE="$2"
    shift 2
    [[ "${1:-}" == "--from" ]] || { echo "ERROR: --add-backlog requires --from <slug>" >&2; exit 2; }
    [[ $# -ge 2 ]] || { echo "ERROR: --from requires a value" >&2; exit 2; }
    FROM="$2"
    ensure_index
    LINE="- [ ] $TITLE — from $FROM"
    insert_under_section "Backlog" "$LINE" "$TITLE"
    ;;

  -h|--help|"")
    cat <<EOF
Usage:
  update-index.sh --add-in-progress <note-file>
  update-index.sh --mark-completed <slug>
  update-index.sh --add-backlog <title> --from <source-slug>
EOF
    [[ "${1:-}" == "" ]] && exit 2 || exit 0
    ;;

  *)
    echo "Unknown command: $1" >&2
    exit 2
    ;;
esac
