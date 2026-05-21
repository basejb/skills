# learning-companion

공식 문서/외부 자료를 5단계 능동 학습 파이프라인으로 통과시키고, 학습 노트를 `~/learning-notes/`에 누적한다.

## 핵심 가치

- 쉽게 풀어주는 챗봇이 아니다
- **더 깊이 생각하게** 만든다
- **원천 소스를 다시 보게** 만든다 (모든 채점에 원문 인용 근거)
- **다음 학습으로 이어지게** 만든다 (Next-Step → INDEX backlog 자동 누적)

## 사용법

```text
이 문서 같이 학습하자 https://www.anthropic.com/research/building-effective-agents
```

또는

```text
/learn https://www.anthropic.com/research/building-effective-agents
```

### 이어 하기

```text
지난번 학습 이어서 하자
```

→ 스킬이 `~/learning-notes/INDEX.md`의 In Progress 섹션을 보여주고 사용자가 선택.

### 단계 진입점

```text
이 문서 퀴즈만 내줘 https://...
이 문서 요약만 https://...
이 개념 재설명해줘 (현재 노트 컨텍스트에서)
```

## 5단계 흐름

1. **Source Capture** — 자료 수집, 한 줄 요약, 핵심 개념 3–7개
2. **Feynman Re-explain** — 인용 → 풀어쓰기 → 비유 → 반례
3. **Active Recall Quiz** — 3–5문항, 1문항씩, 원문 인용 채점
4. **Metacognition** — 왜 헷갈렸는지 / 빠진 사전지식 / 다음에 어떻게 다르게 읽을지
5. **Next-Step Link** — 후속 주제 3개 → INDEX backlog 누적

각 단계 사이에 체크인. 중단 자유.

## 산출물 위치

```
~/learning-notes/
├── INDEX.md                          # In Progress / Completed / Backlog
├── 2026-05-21-anthropic-agents.md
└── 2026-05-22-mcp-protocol.md
```

노트는 Markdown이므로 Obsidian/VSCode 등 어떤 에디터에서도 열린다.

## 참고

- 디자인 스펙: `SPEC.md`
- 노트 정식 스키마: `references/note-template.md`
- 단계별 상세 가이드: `references/feynman-technique.md`, `active-recall-quiz-design.md`, `metacognition-prompts.md`
