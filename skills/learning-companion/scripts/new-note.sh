#!/bin/bash
set -euo pipefail

NOTES_DIR="${LEARNING_NOTES_DIR:-$HOME/learning-notes}"

TITLE=""
SOURCE=""
SLUG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) TITLE="$2"; shift 2 ;;
    --source) SOURCE="$2"; shift 2 ;;
    --slug) SLUG="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: new-note.sh --title <title> --source <url> [--slug <slug>]"
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$TITLE" ]]; then
  echo "ERROR: --title is required" >&2
  exit 2
fi

if [[ -z "$SLUG" ]]; then
  # title → slug 변환: 소문자, 영숫자만 남기고, 공백→하이픈
  SLUG=$(echo "$TITLE" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9 ]//g' \
    | sed 's/  */-/g' \
    | sed 's/^-//; s/-$//')
fi

if [[ -z "$SLUG" ]]; then
  echo "ERROR: could not derive slug from title" >&2
  exit 2
fi

mkdir -p "$NOTES_DIR"

DATE=$(date +%Y-%m-%d)
NOTE_PATH="$NOTES_DIR/${DATE}-${SLUG}.md"

if [[ -e "$NOTE_PATH" ]]; then
  echo "ERROR: note already exists: $NOTE_PATH" >&2
  exit 1
fi

cat > "$NOTE_PATH" <<EOF
---
title: $TITLE
source: $SOURCE
captured: $DATE
status: in-progress
tags: []
next: []
---

## Source
- 한 줄 요약:
- 핵심 개념 (3-7):
- 메타:

## Concepts (Feynman)

## Quiz

## Reflection (Metacognition)
- 가장 헷갈렸던 지점:
- 빠진 사전지식:
- 다음에 비슷한 자료를 만나면 어떻게 다르게 읽을지:

## Next
EOF

echo "$NOTE_PATH"
