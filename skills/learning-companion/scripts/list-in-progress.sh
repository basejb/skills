#!/bin/bash
set -euo pipefail

NOTES_DIR="${LEARNING_NOTES_DIR:-$HOME/learning-notes}"
INDEX="$NOTES_DIR/INDEX.md"

[[ -f "$INDEX" ]] || exit 0

awk '
  /^## In Progress$/ {f=1; next}
  /^## / {f=0}
  f && /^- / {print}
' "$INDEX"
