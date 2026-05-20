---
name: dockerfile-optimizer
description: |
  Dockerfile을 빌드 속도·이미지 크기·보안·배포 안정성 관점에서 분석하고
  개선안을 제안하는 스킬. "Dockerfile 점검/최적화/리뷰", "이미지 크기 줄여줘",
  "빌드 느려", "도커 보안 점검", "root 사용 경고" 같은 요청에 발동. Node.js·
  Python·Go 프로젝트의 패키지 매니저를 lockfile로 감지하여 multi-stage·
  레이어 캐시·non-root 사용자·.dockerignore 등을 자동 진단한다.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Edit
  - Bash(find:*)
  - Bash(wc:*)
  - Bash(file:*)
  - Bash(scripts/detect-stack.sh:*)
  - Bash(hadolint:*)
  - Bash(command -v hadolint:*)
---

# Dockerfile Optimizer

Dockerfile을 분석하고 빌드 속도·이미지 크기·보안·배포 안정성 관점에서 개선안을 제안한다. 사용자가 명시 승인하기 전까지 어떤 파일도 만지지 않는다.

## When to Use

다음 발화에서 발동:

**explicit (의도=optimize 기본):**
- "Dockerfile 점검/리뷰/분석/최적화/봐줘"
- "도커파일 검사"
- "Dockerfile 개선"

**resource (의도=optimize):**
- "이미지 크기 줄여줘"
- "도커 이미지 작게"
- "빌드 느려" / "Docker 빌드 캐시 안 먹혀"

**security (의도=security):**
- "도커 보안 점검"
- "root 사용 경고"
- "컨테이너 보안 감사"
- "이미지에 시크릿 있나"

**review-only 의도 키워드:**
- "리뷰만", "점검만", "분석만" → 적용 흐름 생략

CWD 또는 사용자가 지정한 경로에 `Dockerfile*`이 존재해야 한다. 없으면 "Dockerfile을 찾을 수 없습니다"로 종료. 자동 생성 금지.

## Workflow

### [1] 컨텍스트 수집

- Glob: `**/Dockerfile*`, `**/docker-compose*.y*ml`, `**/.dockerignore`
- 의도 분류: `review` / `optimize` / `security`

### [2] 다중 파일 디스앰비귀에이션

Dockerfile이 2개 이상이면 AskUserQuestion으로 선택받는다 (전체 / 특정 1개 / 특정 다중).

### [3] 스택 감지

`Bash(scripts/detect-stack.sh <dockerfile-dir>)` 호출. 출력 JSON 파싱:

```json
{
  "language": "node|python|go",
  "package_manager": "npm|pnpm|yarn|pip|poetry|uv|go",
  "has_native_deps": true|false,
  "framework_hint": "nestjs|nextjs|express|fastify|fastapi|django|flask|unknown"
}
```

`has_native_deps=true`면 ImageSize 룰 DFO-SIZE-002 (alpine 추천)을 **비활성화**한다.

### [4] 룰 엔진

Dockerfile을 라인별로 읽고, 4개 룰 카테고리 references를 적용:

- `references/rules-security.md` — DFO-SEC-001 ~ 008 (8개)
- `references/rules-performance.md` — DFO-PERF-001 ~ 005 (5개)
- `references/rules-image-size.md` — DFO-SIZE-001 ~ 005 (5개)
- `references/rules-reliability.md` — DFO-REL-001 ~ 006 (6개)

각 룰의 Detection 섹션에 따라 매칭. 매칭 시 `findings[]`에 `{rule_id, severity, line, evidence, message}` 추가.

### [5] hadolint (선택)

`Bash(command -v hadolint)` 호출. exit 0이면 `Bash(hadolint --format json <Dockerfile>)` 실행. 결과는 리포트의 "External Linter Findings" 섹션에 별도 부착, 점수 미반영.

미설치 시 리포트 하단에 1회 안내: `💡 hadolint가 설치돼 있으면 추가 룰까지 점검됩니다. (brew install hadolint)`. 같은 세션에서 반복 안내 금지.

hadolint 실행 실패 시 에러 무시, 룰 기반 결과만 출력.

### [6] 점수 계산

심각도별 감점:
- critical: -10
- major: -5
- minor: -2
- info: 0

카테고리별: `점수 = max(0, 배점 - sum(감점))`
- Security: 40
- Performance: 25
- ImageSize: 20
- Reliability: 15

총점 = 합. 등급: 90+ A / 80+ B / 70+ C / 60+ D / <60 F.

### [7] 리포트 + 개선안

`references/report-template.md` 구조에 따라 마크다운 출력. 채팅 인라인. 파일 저장 X.

개선 Dockerfile은 `references/presets-{language}.md`에서 사용자 패키지 매니저에 맞는 템플릿을 가져와 **사용자 프로젝트의 빌드 명령에 맞게 수정**한다 (단순 복사 금지).

`.dockerignore` 부족 시 `references/dockerignore-base.md`에서 언어별 권장 내용 가져와 리포트에 코드블록으로 표시. 파일 자동 생성 금지.

### [8] 의도별 분기

- **optimize** (기본): 리포트 + 풀버전 개선 Dockerfile + diff + 적용 안내
- **review**: 리포트 + 개선 Dockerfile은 보여주되 적용 안내 제거
- **security**: Security 룰 위로 끌어올려 표시, 다른 카테고리는 룰 ID만 나열. 개선 Dockerfile은 보안 항목 위주

### [9] 사용자 승인 대기

리포트 출력 직후 **반드시 `AskUserQuestion` 도구를 호출**해서 사용자가 텍스트를 입력하지 않고 선택만으로 진행할 수 있게 한다. 의도별로 질문 구성이 다르다.

#### intent = `optimize` (기본)

```
question: "위 개선안을 어떻게 적용할까요?"
header: "적용 방식"
multiSelect: false
options:
  1. label: "전체 적용 (Dockerfile + .dockerignore)"
     description: "제안된 모든 변경을 적용합니다. 가장 빠르고 일관된 결과."
     (Recommended — label 끝에 "(Recommended)" 표시)
     → .dockerignore가 이미 충분하거나 .dockerignore 권장 섹션이 없으면 옵션 라벨은 "전체 적용 (Dockerfile)" 으로 자동 변경

  2. label: "Dockerfile만 적용"
     description: ".dockerignore는 그대로 두고 Dockerfile만 갱신."
     (.dockerignore 권장 섹션이 있을 때만 표시)

  3. label: ".dockerignore만 만들기"
     description: "Dockerfile은 유지, .dockerignore만 새로 생성/갱신."
     (.dockerignore 권장 섹션이 있을 때만 표시)

  4. label: "선택 적용 — 번호로 지정"
     description: '예: "1, 3번만 적용". 채팅으로 finding 번호를 알려주세요.'

  5. label: "적용 안 함 (리뷰만)"
     description: "어떤 파일도 수정하지 않고 종료."
```

> 옵션 4를 선택하면 사용자가 후속 메시지로 finding 번호를 보낼 때까지 대기. 옵션 5를 선택하면 [10] 단계로 가지 않고 종료.

#### intent = `security`

```
question: "보안 항목을 어떻게 적용할까요?"
header: "적용 방식"
multiSelect: false
options:
  1. label: "보안 항목만 적용 (Recommended)"
     description: "Security 카테고리 finding에 해당하는 변경만 적용 — USER 추가, 시크릿 제거 등."

  2. label: "전체 최적화 적용"
     description: "보안 외 Performance/ImageSize/Reliability 개선도 모두 적용."

  3. label: "선택 적용 — 번호로 지정"
     description: '예: "1, 3번만 적용".'

  4. label: "적용 안 함 (리뷰만)"
     description: "어떤 파일도 수정하지 않고 종료."
```

#### intent = `review`

`AskUserQuestion` 호출 **금지**. 리뷰 전용 모드이므로 적용 안내 자체를 생략하고 종료. 사용자가 후속으로 "최적화해줘" 발화하면 그때 새 분석 사이클로 들어간다.

#### 다중 Dockerfile

분석한 Dockerfile이 2개 이상이면 위 질문 위에 한 단계 더 추가:

```
question: "어떤 파일에 적용할까요?"
header: "적용 대상"
multiSelect: true
options: 각 Dockerfile 경로 (점수 낮은 순) + "전체 (Recommended)"
```

선택된 Dockerfile들에 대해서만 위의 적용 방식 질문을 한 번 더 묻는다.

#### 안전 규칙

- `AskUserQuestion`을 호출하지 않고 임의로 Edit/Write 호출 **금지**
- 사용자가 옵션 5(또는 보안 모드의 옵션 4) "적용 안 함"을 선택하면 [10] 단계 스킵, 짧은 마무리 한 줄만 출력
- 사용자가 도구 사용 거부 / 응답 없음 / 다른 주제로 전환 시 어떤 파일도 만지지 않는다

### [10] 적용 + 마무리

[9]에서 사용자가 "적용 안 함"을 선택했으면 이 단계는 **스킵**하고 한 줄 마무리 ("적용 없이 종료. 다시 검토하려면 다시 불러주세요.")만 출력.

적용을 선택한 경우:

1. 적용 직전 변경 요약 1줄 출력 ("Dockerfile에 multi-stage 빌드 적용, USER 추가; .dockerignore 생성")
2. Edit/Write 호출로 실제 파일 수정 — 사용자가 선택한 범위(전체 / Dockerfile만 / .dockerignore만 / 특정 finding 번호)만 반영
3. 적용 후 변경된 파일 경로 나열
4. 마지막에 적용 / 보류 / 사용자 확인 필요 항목 분리 표시

"선택 적용 — 번호로 지정"을 골랐던 경우에는 사용자가 후속 메시지로 번호를 보내올 때까지 대기하고, 받은 후 위 단계를 실행한다.

## Edge Cases

- **BuildKit 헤더 (`# syntax=docker/dockerfile:1.x`)**: 정상 처리, `--mount=type=cache` 등 BuildKit 기능 추천 활성화
- **1000줄 초과 Dockerfile (`wc -l` 기준)**: 경고 후 진행 ("매우 큰 Dockerfile입니다. 분석 정확도가 떨어질 수 있어요")
- **파싱 실패 (BOM, 비표준 인코딩)**: 사용자에게 알리고 hadolint 결과로만 폴백
- **Dockerfile 0개**: "Dockerfile을 찾을 수 없습니다"로 종료. 자동 생성 금지

## Rule Index

| ID | Category | Severity | Title |
|---|---|---|---|
| DFO-SEC-001 | Security | critical | Container runs as root |
| DFO-SEC-002 | Security | critical | Container explicitly runs as root |
| DFO-SEC-003 | Security | critical | Secret files copied into image |
| DFO-SEC-004 | Security | major | Secret-like ARG or ENV declarations |
| DFO-SEC-005 | Security | major | ADD <URL> without checksum |
| DFO-SEC-006 | Security | major | Base image tag is `latest` or missing |
| DFO-SEC-007 | Security | minor | apt-get without --no-install-recommends |
| DFO-SEC-008 | Security | major | curl ... \| sh pattern |
| DFO-PERF-001 | Performance | major | Source COPY before dependency install |
| DFO-PERF-002 | Performance | major | Install command does not respect lockfile |
| DFO-PERF-003 | Performance | minor | Consecutive RUN commands not combined |
| DFO-PERF-004 | Performance | minor | apt-get update without cache cleanup |
| DFO-PERF-005 | Performance | minor | BuildKit cache mount not used for large deps |
| DFO-SIZE-001 | ImageSize | major | Multi-stage build not used |
| DFO-SIZE-002 | ImageSize | minor | Full base image used (slim/alpine candidate) |
| DFO-SIZE-003 | ImageSize | major | devDependencies present in runtime stage |
| DFO-SIZE-004 | ImageSize | major | .dockerignore missing or incomplete |
| DFO-SIZE-005 | ImageSize | minor | No cleanup after package installs |
| DFO-REL-001 | Reliability | major | CMD uses shell form |
| DFO-REL-002 | Reliability | minor | ENTRYPOINT uses shell form |
| DFO-REL-003 | Reliability | minor | WORKDIR not set |
| DFO-REL-004 | Reliability | minor | Server-like CMD without EXPOSE |
| DFO-REL-005 | Reliability | info | HEALTHCHECK missing |
| DFO-REL-006 | Reliability | minor | Missing standard runtime env vars |

## Adding New Rules

새 룰을 추가할 때:

1. 해당 카테고리 `references/rules-<category>.md`에 룰 추가 (ID, severity, deduction, detection, why, bad/good 예)
2. `SKILL.md`의 Rule Index 표에 한 줄 추가
3. `tests/fixtures/<rule-id>-bad/Dockerfile` 위반 예 추가
4. `tests/fixtures/<rule-id>-good/Dockerfile` 정상 예 추가
5. `tests/expected/<rule-id>-*.md`에 기대 결과 명시

## References

- `references/rules-security.md`
- `references/rules-performance.md`
- `references/rules-image-size.md`
- `references/rules-reliability.md`
- `references/presets-nodejs.md`
- `references/presets-python.md`
- `references/presets-go.md`
- `references/dockerignore-base.md`
- `references/report-template.md`
