# Note Template

학습 노트 한 개의 정식 스키마. `scripts/new-note.sh`가 이 구조의 파일을 생성한다. 5단계 파이프라인을 통과하면서 각 섹션이 채워진다.

## Frontmatter

```yaml
---
title: "<자료 제목>"          # 필수, YAML 큰따옴표로 감쌈
source: "<원문 URL 또는 파일 경로>"  # 필수, YAML 큰따옴표로 감쌈
captured: YYYY-MM-DD          # 필수 (생성일)
status: in-progress           # in-progress | completed | abandoned | partial
tags: [tag1, tag2]            # 자유 태그, 검색용
next: [slug1, slug2]          # Next-Step에서 연결된 후속 노트 슬러그
---
```

### status 값

| 값 | 의미 |
|---|---|
| `in-progress` | 5단계 중 일부만 완료. 재개 가능 |
| `completed` | 5단계 모두 완료 |
| `abandoned` | 더 진행하지 않기로 결정 (이유는 Reflection에 기록) |
| `partial` | 사용자가 의도적으로 일부 단계만 수행 (예: "퀴즈만") |

## Sections

### `## Source` (Stage 1)

- **한 줄 요약**: 자료 전체를 한 문장으로
- **핵심 개념 (3-7)**: bullet, 각각 한 줄
- **메타**: 작성자 / 길이 / 난이도 (사용자 체감)

### `## Concepts (Feynman)` (Stage 2)

핵심 개념별로 `### 개념 N: <이름>` 서브섹션. 각 서브섹션은:

- **정의(원문)**: 자료 원문의 정의 인용
- **내 말로**: 사용자가 다시 쓰는 설명
- **비유**: 일상적/다른 도메인의 비유
- **반례 / 자주 헷갈리는 지점**: 이 개념이 아닌 것

### `## Quiz` (Stage 3)

3–5문항. 각 문항:

```
N. Q: <질문>
   내 답: <사용자 답변>
   정답: <정답>
   근거(원문 인용): "<원문 발췌>"
```

### `## Reflection (Metacognition)` (Stage 4)

- **가장 헷갈렸던 지점**:
- **빠진 사전지식**:
- **다음에 비슷한 자료를 만나면 어떻게 다르게 읽을지**:

### `## Next` (Stage 5)

체크박스 목록. 3개 권장.

```
- [ ] <후속 자료/개념 이름> — <왜 이어 봐야 하는지>
```

`scripts/update-index.sh --add-backlog`로 INDEX.md의 Backlog 섹션에 동기화된다.

## 예시 (완료된 노트)

```markdown
---
title: "Building Effective Agents"
source: "https://www.anthropic.com/research/building-effective-agents"
captured: 2026-05-21
status: completed
tags: [ai-agent, anthropic]
next: [mcp-protocol]
---

## Source
- 한 줄 요약: Agent = LLM + tools + loop. Workflow = 미리 정의된 코드 경로.
- 핵심 개념: Workflow vs Agent / Tool use / Planning / Reflection
- 메타: Anthropic Research, 약 4000자, 중

## Concepts (Feynman)
### 개념 1: Workflow vs Agent
- 정의(원문): Workflows orchestrate LLMs via predefined code paths.
- 내 말로: 흐름이 코드에 박혀 있으면 워크플로, LLM이 매번 결정하면 에이전트.
- 비유: 자동 세차 vs 사람 세차.
- 반례: ReAct가 들어가도 한 번만 도는 if-else면 워크플로.

## Quiz
1. Q: Workflow와 Agent의 결정 시점 차이는?
   내 답: 워크플로는 사전에, 에이전트는 런타임에
   정답: 동일
   근거: "Agents... dynamically direct their own processes"

## Reflection (Metacognition)
- 가장 헷갈렸던 지점: ReAct가 에이전트인지 워크플로인지
- 빠진 사전지식: tool use loop의 종료 조건
- 다음에 비슷한 자료 읽을 때: "loop가 있나"를 먼저 체크

## Next
- [ ] MCP Protocol Spec — Agent의 tool 인터페이스 표준
```
