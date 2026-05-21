---
name: learning-companion
description: |
  공식 문서/외부 자료(URL·로컬 파일)를 5단계 능동 학습 파이프라인
  (Source → Feynman → Active Recall → Metacognition → Next-Step)으로
  통과시켜 ~/learning-notes/에 누적 노트로 영속화하는 스킬.
  "이 문서 학습/공부하자", "/learn <url>", "[주제] 같이 봐줘",
  "지난번 학습 이어서" 같은 발화에서 발동. 단순 요약·번역·일반
  질의응답은 트리거하지 않는다.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - WebFetch
  - Bash(scripts/new-note.sh:*)
  - Bash(scripts/update-index.sh:*)
  - Bash(scripts/list-in-progress.sh:*)
  - Bash(mkdir -p:*)
  - Bash(ls:*)
  - Bash(cat:*)
---

# Learning Companion

외부 자료를 5단계 파이프라인으로 통과시켜 **사용자가 더 깊이 생각하게** 만든다. 쉽게 풀어주는 챗봇이 아니라, 원천 소스를 다시 보게 만들고 다음 학습으로 이어지게 만드는 도구다.

## When to Use

### 발동

**explicit:**
- "이 문서 학습해줘 / 공부하자 / 같이 보자" + URL/파일
- "/learn <url-or-path>"
- "[주제] 학습 시작"

**resource:**
- URL을 던지면서 "정리 + 퀴즈"가 함의된 발화
- "Anthropic agent 문서 같이 봐줘"

**continuation:**
- "지난번 ~ 이어서 하자" → `bash scripts/list-in-progress.sh`로 후보 확인 → 사용자에게 선택지 제시 후 재개

### 발동 안 함

- 자료 없는 "X가 뭐야?" 단순 질문
- 코드베이스 onboarding (`/init` 영역)
- 자료의 단순 번역·요약만 요구

## Five-Stage Pipeline

각 단계 종료 후 **"다음 단계로 가시겠습니까? 아니면 이 단계를 더 파고들까요?"** 체크인. 사용자가 멈추면 노트는 현재 상태(`status: in-progress` 또는 `partial`)로 저장.

### Stage 0: 노트 생성

자료가 확보되면 즉시 노트 파일을 만든다.

```bash
bash scripts/new-note.sh --title "<자료 제목>" --source "<URL 또는 경로>"
```

생성된 경로를 사용자에게 알린다. 동일 자료 재학습 시도면 기존 노트 발견 → "이어 하기 / 새로 시작 / 그만두기" 3지선다 제시.

생성 직후 INDEX 등록:

```bash
bash scripts/update-index.sh --add-in-progress <생성된-노트-경로>
```

### Stage 1: Source Capture

WebFetch(URL) 또는 Read(로컬 파일)로 자료 수집. 노트의 `## Source` 섹션에 채운다:

- 한 줄 요약
- 핵심 개념 3–7개 (bullet)
- 메타: 작성자/길이/난이도

자료가 너무 길면 (>50K 토큰) 챕터 단위로 잘라 진행할지 사용자에게 물어본다. 챕터별 노트 분리 가능.

### Stage 2: Feynman Re-explain

상세 가이드: `references/feynman-technique.md`

핵심: 원문 인용 → 풀어쓰기 → 비유 → 반례. 한 개념씩 사용자 체크인. 노트의 `## Concepts (Feynman)` 섹션에 `### 개념 N: <이름>` 서브섹션으로 누적.

### Stage 3: Active Recall Quiz

상세 가이드: `references/active-recall-quiz-design.md`

- 3–5문항, **1문항씩** 출제 → 답변 → 채점(원문 인용 근거 포함) → 다음 문항
- 일괄 출제 금지
- 오답 시 Stage 4로 자연스럽게 전이

노트의 `## Quiz` 섹션에 (Q / 내 답 / 정답 / 근거) 형태로 누적.

### Stage 4: Metacognition

상세 가이드: `references/metacognition-prompts.md`

진단 3축(사전지식 / 추론 경로 / 재구성) 중 최소 1축에 대한 사용자 응답을 받는다. **사용자 1인칭**으로 노트의 `## Reflection (Metacognition)`에 기록.

### Stage 5: Next-Step Link

자료 내에서 언급된 / 가정된 / 더 깊이 다룰 후속 주제 3개 추천. 각 항목에 "왜 이어 봐야 하는지" 명시. 노트의 `## Next` 섹션에 체크박스로 작성하고, 같은 항목을 INDEX.md backlog에 자동 등록:

```bash
bash scripts/update-index.sh --add-backlog "<후속 주제>" --from "<현재 slug>"
```

5단계 모두 완료 시 INDEX의 In Progress → Completed 이동:

```bash
bash scripts/update-index.sh --mark-completed "<현재 slug>"
```

그리고 노트의 frontmatter `status: in-progress` → `status: completed`로 Edit.

## 단계 진입점 (Sub-flows)

사용자가 특정 단계만 원할 수 있다.

| 발화 | 동작 | status |
|---|---|---|
| "퀴즈만" | Stage 3만 수행 | `partial` |
| "재설명만" | Stage 2만 수행 | `partial` |
| "요약만" | Stage 1만 수행 | `partial` |

`partial` 노트도 INDEX의 In Progress 섹션에 들어가 재개 가능.

## 노트 위치 & INDEX

- 저장 위치: `~/learning-notes/YYYY-MM-DD-<slug>.md`
- 인덱스: `~/learning-notes/INDEX.md` (In Progress / Completed / Backlog 3섹션)
- 정식 스키마: `references/note-template.md`

스크립트 사용 패턴:

- 새 노트: `bash scripts/new-note.sh --title "X" --source "Y"`
- INDEX에 in-progress 추가: `bash scripts/update-index.sh --add-in-progress <note-file>` (Stage 0 직후)
- 완료 처리: `bash scripts/update-index.sh --mark-completed <slug>` (Stage 5 완료 시)
- Backlog 추가: `bash scripts/update-index.sh --add-backlog "<title>" --from "<slug>"`
- 진행 중 조회: `bash scripts/list-in-progress.sh`

## 세션 종료 시 처리

- 5단계 모두 완료 → `--mark-completed` + frontmatter `status: completed`
- 일부만 완료 → 노트의 frontmatter `status: in-progress` 유지 (별도 처리 없음)
- 의도적 일부 단계 → `status: partial`로 노트 수정 (`Edit` 사용)

## Edge Cases

| 케이스 | 처리 |
|---|---|
| WebFetch 실패 (paywall, JS 렌더링) | 사용자에게 로컬 사본 요청 |
| 자료가 너무 김 | 챕터 단위 분할 합의 |
| 동일 URL 재학습 | 기존 노트 발견 시 3지선다 (이어 하기 / 새로 시작 / 그만두기) |
| 외국어 자료 | 원문 인용은 원어 유지, 설명·퀴즈는 한국어 |
| INDEX 갱신 실패 | 스크립트가 idempotent하므로 재실행 |

## 안티패턴 (이 스킬이 되지 말아야 할 모습)

- 자료 없이 "X 설명해줘"에 응답 (이건 일반 응답)
- 5단계를 한 번에 자동으로 통과 (사용자 체크인 생략)
- 채점 시 원문 인용 없이 정답만 알려주기
- Metacognition 응답을 AI가 3인칭으로 적기
- Next-Step을 INDEX에 누락 (다음 학습으로 이어지는 핵심 가치)
