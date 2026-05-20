#!/bin/bash
set -euo pipefail

DETECT="$(cd "$(dirname "$0")/.." && pwd)/scripts/detect-stack.sh"
TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$TEST_TMPDIR"' EXIT

PASS=0
FAIL=0

run_case() {
  local name="$1"
  local expected_lang="$2"
  local expected_pm="$3"
  local extra_check="${4:-}"
  shift 4 2>/dev/null || shift $#

  local case_dir="$TEST_TMPDIR/$name"
  mkdir -p "$case_dir"

  for f in "$@"; do
    if [[ "$f" == *":"* ]]; then
      local fname="${f%%:*}"
      local content="${f#*:}"
      echo "$content" > "$case_dir/$fname"
    else
      touch "$case_dir/$f"
    fi
  done

  local actual
  actual=$("$DETECT" "$case_dir")

  local ok=1
  echo "$actual" | grep -q "\"language\": \"$expected_lang\"" || ok=0
  echo "$actual" | grep -q "\"package_manager\": \"$expected_pm\"" || ok=0
  if [[ -n "$extra_check" ]]; then
    echo "$actual" | grep -q "$extra_check" || ok=0
  fi

  if [[ $ok -eq 1 ]]; then
    echo "PASS: $name"
    PASS=$((PASS+1))
  else
    echo "FAIL: $name"
    echo "  Expected: language=$expected_lang, package_manager=$expected_pm, extra=$extra_check"
    echo "  Actual: $actual"
    FAIL=$((FAIL+1))
  fi
}

run_case "pnpm"      "node"   "pnpm"   ""                              "pnpm-lock.yaml" "package.json"
run_case "yarn"      "node"   "yarn"   ""                              "yarn.lock"      "package.json"
run_case "npm-lock"  "node"   "npm"    ""                              "package-lock.json" "package.json"
run_case "npm-only"  "node"   "npm"    ""                              "package.json"
run_case "uv"        "python" "uv"     ""                              "uv.lock"        "pyproject.toml"
run_case "poetry"    "python" "poetry" ""                              "poetry.lock"    "pyproject.toml"
run_case "pip-req"   "python" "pip"    ""                              "requirements.txt"
run_case "pip-pyp"   "python" "pip"    ""                              "pyproject.toml"
run_case "go"        "go"     "go"     ""                              "go.mod"
run_case "empty"     ""       ""       ""                              "README.md"

# Native deps detection (Node.js)
run_case "native-bcrypt" "node" "npm" "\"has_native_deps\": true" \
  "package.json:{\"dependencies\":{\"bcrypt\":\"^5.0.0\"}}"
run_case "native-sharp" "node" "npm" "\"has_native_deps\": true" \
  "package.json:{\"dependencies\":{\"sharp\":\"^0.32.0\"}}"
run_case "non-native" "node" "npm" "\"has_native_deps\": false" \
  "package.json:{\"dependencies\":{\"express\":\"^4.0.0\"}}"

# Framework hint
run_case "fw-nestjs" "node" "npm" "\"framework_hint\": \"nestjs\"" \
  "package.json:{\"dependencies\":{\"@nestjs/core\":\"^10.0.0\"}}"
run_case "fw-nextjs" "node" "npm" "\"framework_hint\": \"nextjs\"" \
  "package.json:{\"dependencies\":{\"next\":\"^14.0.0\"}}"
run_case "fw-express" "node" "npm" "\"framework_hint\": \"express\"" \
  "package.json:{\"dependencies\":{\"express\":\"^4.0.0\"}}"

# uv.lock + poetry.lock both present → uv wins
run_case "uv-over-poetry" "python" "uv" "" "uv.lock" "poetry.lock" "pyproject.toml"

# requirements.txt + pyproject.toml without uv/poetry → pip (priority resolves to pip either way)
run_case "pip-combo" "python" "pip" "" "requirements.txt" "pyproject.toml"

# False positive guard: package.json with "sharp" in description but not in deps
run_case "false-pos-keyword" "node" "npm" "\"has_native_deps\": false" \
  "package.json:{\"description\":\"uses sharp images\",\"dependencies\":{\"express\":\"^4.0.0\"}}"

# Non-existent directory should exit 1 with error JSON on stderr
echo ""
echo "--- Edge: non-existent directory ---"
err_out=$("$DETECT" /nonexistent-path-zzz-detect-stack-test 2>&1 1>/dev/null || true)
err_exit=$("$DETECT" /nonexistent-path-zzz-detect-stack-test >/dev/null 2>&1; echo $?)
if echo "$err_out" | grep -q '"error"' && [[ "$err_exit" == "1" ]]; then
  echo "PASS: error-no-dir"
  PASS=$((PASS+1))
else
  echo "FAIL: error-no-dir"
  echo "  stderr: $err_out"
  echo "  exit: $err_exit"
  FAIL=$((FAIL+1))
fi

echo ""
echo "Total: $((PASS+FAIL)) | Pass: $PASS | Fail: $FAIL"
[[ $FAIL -eq 0 ]]
