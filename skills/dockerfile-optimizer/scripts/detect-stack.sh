#!/bin/bash
set -euo pipefail

TARGET_DIR="${1:-$PWD}"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo '{"error": "target directory not found"}' >&2
  exit 1
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
cd "$TARGET_DIR"

LANGUAGE=""
PKG_MANAGER=""
HAS_NATIVE_DEPS="false"
FRAMEWORK_HINT="unknown"

# Language + package manager detection (priority: lockfile > config)
if [[ -f "pnpm-lock.yaml" ]]; then
  LANGUAGE="node"; PKG_MANAGER="pnpm"
elif [[ -f "yarn.lock" ]]; then
  LANGUAGE="node"; PKG_MANAGER="yarn"
elif [[ -f "package-lock.json" ]]; then
  LANGUAGE="node"; PKG_MANAGER="npm"
elif [[ -f "package.json" ]]; then
  LANGUAGE="node"; PKG_MANAGER="npm"
elif [[ -f "uv.lock" ]]; then
  LANGUAGE="python"; PKG_MANAGER="uv"
elif [[ -f "poetry.lock" ]]; then
  LANGUAGE="python"; PKG_MANAGER="poetry"
elif [[ -f "pyproject.toml" || -f "requirements.txt" ]]; then
  LANGUAGE="python"; PKG_MANAGER="pip"
elif [[ -f "go.mod" ]]; then
  LANGUAGE="go"; PKG_MANAGER="go"
fi

# Native deps (Node.js only — package.json deps inspection)
if [[ "$LANGUAGE" == "node" && -f "package.json" ]]; then
  if grep -qE '"(sharp|bcrypt|canvas|node-gyp|@swc/core|node-sass|grpc|node-pre-gyp|argon2|sqlite3|better-sqlite3)"[[:space:]]*:' package.json; then
    HAS_NATIVE_DEPS="true"
  fi
fi

# Framework hint
if [[ "$LANGUAGE" == "node" && -f "package.json" ]]; then
  if grep -q '"@nestjs/core"' package.json; then
    FRAMEWORK_HINT="nestjs"
  elif grep -q '"next"' package.json; then
    FRAMEWORK_HINT="nextjs"
  elif grep -q '"express"' package.json; then
    FRAMEWORK_HINT="express"
  elif grep -q '"fastify"' package.json; then
    FRAMEWORK_HINT="fastify"
  fi
elif [[ "$LANGUAGE" == "python" && -f "pyproject.toml" ]]; then
  if grep -qE "fastapi|django|flask" pyproject.toml; then
    FRAMEWORK_HINT=$(grep -oE "fastapi|django|flask" pyproject.toml | head -1)
  fi
fi

cat <<EOF
{
  "language": "$LANGUAGE",
  "package_manager": "$PKG_MANAGER",
  "has_native_deps": $HAS_NATIVE_DEPS,
  "framework_hint": "$FRAMEWORK_HINT"
}
EOF
