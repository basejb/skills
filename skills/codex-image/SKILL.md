---
name: codex-image
description: |
  Generate images via Codex CLI's built-in image_gen tool (gpt-image-2). OAuth auth — no API key needed.
  Codex CLI의 내장 image_gen 도구로 이미지 생성. OAuth 인증으로 API 키 불필요.
  Usage: /codex-image cherry blossom hanok, /codex-image --size 1024x1536 space cat, /codex-image --quality high seoul night
argument-hint: "[--size <WxH>] [--quality low|medium|high] [--background transparent|opaque|auto] [--out <path>] [-n <count>] [--reference <path>]... <image prompt>"
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# codex-image — AI Image Generation via Codex OAuth

Generate images using OpenAI's `gpt-image-2` model through Codex CLI.
**No API key required** — uses Codex OAuth (ChatGPT login) authentication.

OpenAI Codex CLI의 내장 `image_gen` 도구를 통해 `gpt-image-2` 모델로 이미지를 생성한다.
**API 키 불필요** — Codex OAuth(ChatGPT 로그인) 인증 사용.

## How it works / 동작 원리

```
User prompt → Claude Code (/codex-image)
  → codex exec (OAuth token auto-managed)
    → built-in image_gen tool (gpt-image-2)
      → ~/.codex/generated_images/<session>/
        → copy to project root
```

> **Important**: OAuth tokens cannot call OpenAI REST API directly (returns 401).
> Must go through `codex exec` which handles auth internally.
>
> OAuth 토큰으로 OpenAI REST API 직접 호출 불가 (401 반환).
> 반드시 `codex exec` 경유 — Codex가 내부적으로 인증 처리.

---

## Step 1 — Verify Codex CLI & Auth / Codex CLI 및 인증 확인

```bash
which codex 2>/dev/null && codex --version 2>/dev/null || echo "NOT_FOUND"
```

If `NOT_FOUND`, stop:
> "Codex CLI not installed. Run `npm install -g @openai/codex` then `codex login`."
> "Codex CLI 없음. `npm install -g @openai/codex` 후 `codex login` 실행해."

```bash
codex login status 2>&1
```

If not "Logged in":
> "Codex login required. Run `codex login` in terminal. OAuth login enables image generation without API key."
> "Codex 로그인 필요. 터미널에서 `codex login` 실행. OAuth 로그인하면 API 키 없이 이미지 생성 가능."

## Step 2 — Parse Arguments / 인자 파싱

Extract from `$ARGUMENTS`:

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--size` | `1024x1024`, `1024x1536`, `1536x1024`, `auto` | `1024x1024` | Image dimensions / 이미지 크기 |
| `--quality` | `low`, `medium`, `high`, `auto` | `auto` | Generation quality / 생성 품질 |
| `--background` | `transparent`, `opaque`, `auto` | `auto` | Background mode. **Important: NOT a true API param** — `gpt-image-2`'s image_gen tool still returns an RGB PNG (no alpha) regardless. With `transparent` set, codex performs a **post-process flood-fill** from the corners to convert the near-white background to alpha (RGBA, color type 6). Works well on plain-bg single-subject illustrations; **fails on designs that have large white interior areas (white clothing, white shapes, white props)** — those will be eroded. **Also: model sometimes paints a literal checkerboard / gray grid pattern as a "transparency indicator" inside the artwork (alpha=255), which the flood-fill cannot remove.** For complex cutouts use an external ML matting step (e.g. `bria/remove-background`) instead. Always include explicit "no checkerboard pattern, no gray grid pattern, no transparency indicator pattern in the artwork itself" in the prompt. / 배경 모드. **OpenAI image_gen 도구는 항상 RGB PNG를 반환**하며, `transparent` 지정 시 codex가 **코너에서 flood-fill 후처리**로 흰 바탕을 알파로 변환한다(RGBA color type 6). 단일 캐릭터/실루엣엔 OK이지만 **디자인 안에 큰 흰색 면적(흰 옷·도형·소품)이 있으면 함께 침식**된다. **또한: 모델이 가끔 "투명 표시"라고 학습한 체커보드/회색 그리드 패턴을 디자인 안에 그려넣음** (alpha=255이라 flood-fill로 제거 안 됨, 2026-04-27 검증) → 프롬프트에 "no checkerboard pattern, no gray grid pattern, no transparency indicator pattern" 반드시 명시. 복잡한 cutout은 bria/remove-background ML 매팅을 쓸 것. |
| `--out` | directory path | project root | Save location / 저장 위치 |
| `-n` | 1–10 | `1` | Number of images / 생성 장수 |
| `--reference` | file path (repeatable) | none | Style reference image(s) attached to the prompt / 스타일 참조 이미지 (반복 가능) |

**Parsing note for `--reference`:** The flag may appear zero or more times. Initialize an empty array before parsing: `_REFERENCES=()`. Append each value with `_REFERENCES+=("$value")`. Path validation and error handling happen in Step 4's bash block — do not re-validate here.

Remaining text → image prompt / 나머지 텍스트 → 이미지 프롬프트

If prompt is empty, ask via AskUserQuestion:
> "What image should I generate? Enter a prompt."
> "어떤 이미지를 생성할까? 프롬프트를 입력해줘."

## Step 3 — Determine Save Path / 저장 경로 결정

```bash
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
_OUT_DIR="${_PROJECT_ROOT}"
_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
_FILENAME="codex-image-${_TIMESTAMP}"
```

- If `--out` specified, use that path / `--out` 지정 시 해당 경로 사용
- Single image: `codex-image-<timestamp>.png`
- Multiple (`-n > 1`): `codex-image-<timestamp>-1.png`, `-2.png`, ...
- Never overwrite existing files / 기존 파일 덮어쓰기 금지

## Step 4 — Generate Image / 이미지 생성

```bash
# Build -i argument array for references (zero or more).
# Array form avoids eval, so paths containing spaces, backticks, or $(...) are
# passed as literal file paths — no shell re-parsing, no injection surface.
_REF_ARGS=()
for ref in "${_REFERENCES[@]}"; do
  if [ ! -f "$ref" ]; then
    echo "ERROR: Reference image not found: $ref" >&2
    exit 1
  fi
  _REF_ARGS+=(-i "$ref")
done

# Include reference hint in the prompt if any references are attached
_REFERENCE_HINT=""
if [ "${#_REF_ARGS[@]}" -gt 0 ]; then
  _REFERENCE_HINT=" Use the attached image(s) as strong style references for tone, color palette, typography, and layout."
fi

_BACKGROUND_LINE=""
if [ -n "${_BACKGROUND}" ] && [ "${_BACKGROUND}" != "auto" ]; then
  _BACKGROUND_LINE="
6. Background: ${_BACKGROUND} — pass background='${_BACKGROUND}' as a parameter to the image_gen tool. When transparent, the saved PNG MUST include an alpha channel (RGBA, color type 6); do not flatten onto white. Verify after generation that the corners of the output are transparent before reporting success."
fi

_CODEX_PROMPT="Perform the following tasks:
1. Use the built-in image_gen tool to generate an image.${_REFERENCE_HINT}
2. Prompt: ${_PROMPT}
3. Size: ${_SIZE}
4. Quality: ${_QUALITY}
5. Count: ${_N}${_BACKGROUND_LINE}
7. Copy the generated image to '${_OUT_DIR}/${_FILENAME}.png'. For multiple images use -1.png, -2.png suffix.
8. Print the saved file path and size."

if [ "${#_REF_ARGS[@]}" -gt 0 ]; then
  # With references: -i flags on command line, prompt on stdin.
  # `codex exec -i <FILE>...` is variadic and would swallow a trailing prompt
  # positional arg as another file path, so the prompt must go to stdin.
  codex exec "${_REF_ARGS[@]}" \
    -C "${_PROJECT_ROOT}" \
    -s workspace-write \
    -c 'model_reasoning_effort="medium"' \
    --skip-git-repo-check \
    <<<"${_CODEX_PROMPT}" 2>&1
else
  # Without references: existing behavior — prompt as positional argument.
  codex exec "${_CODEX_PROMPT}" \
    -C "${_PROJECT_ROOT}" \
    -s workspace-write \
    -c 'model_reasoning_effort="medium"' \
    --skip-git-repo-check \
    2>&1
fi
```

timeout: 120000ms (2 min)

### Required flags / 필수 플래그

- `-s workspace-write` — file write permission / 파일 쓰기 권한
- `--skip-git-repo-check` — works outside git repos / git 레포 외부에서도 실행 가능

### Internal flow (Codex side) / 내부 동작 흐름

1. Codex calls built-in `image_gen` tool (gpt-image-2)
2. Image saved to `~/.codex/generated_images/<session-id>/ig_*.png`
3. Codex copies file to specified project path
4. Reports file path and size

## Step 5 — Display Result / 결과 출력

```
═══════════════════════════════════════════════
IMAGE GENERATED / 이미지 생성 완료
═══════════════════════════════════════════════
Prompt: <prompt used>
Size: <size>
Quality: <quality>
Count: <n>
Auth: OAuth (ChatGPT)
───────────────────────────────────────────────
<saved file path(s)>
═══════════════════════════════════════════════
```

**Always display the generated image using the Read tool.**
**생성된 이미지를 반드시 Read 도구로 표시한다.**

## Step 6 — Follow-up / 후속 안내

- "Run `/codex-image` again to generate another image."
- For Next.js projects: suggest moving to `public/images/` if needed.

## Error Handling / 에러 처리

| Error | Message |
|-------|---------|
| Auth expired | "Codex OAuth expired. Run `codex login` again." / "OAuth 인증 만료. `codex login` 다시 실행." |
| Model access denied | "No access to gpt-image-2. Check your OpenAI plan." / "gpt-image-2 접근 권한 없음. OpenAI 플랜 확인." |
| Timeout (>2min) | "Generation timed out. Try `--quality low`." / "생성 시간 초과. `--quality low`로 재시도." |
| Rate limit | "API rate limited. Wait and retry." / "API 호출 제한. 잠시 후 재시도." |
| Trust error | Check `--skip-git-repo-check` flag or add project to `~/.codex/config.toml` |

## Rules / 규칙

- Always use the Read tool to display generated images / 생성된 이미지는 반드시 Read로 표시
- Never overwrite existing files — always use timestamped filenames / 기존 파일 덮어쓰기 금지
- OAuth only — do not attempt direct REST API calls with OAuth token (returns 401) / OAuth 토큰으로 REST API 직접 호출 금지
- Verify prompt intent before generating / 생성 전 프롬프트 의도 확인
