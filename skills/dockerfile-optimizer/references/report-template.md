# Report Template

LLM이 리포트 생성 시 따라야 할 마크다운 구조. `{{...}}`는 자리표시자.

채팅 인라인 출력. 별도 파일 저장 금지.

---

## 단일 Dockerfile 리포트

~~~markdown
# Dockerfile Review — `{{path}}`

**Score: {{total}} / 100 — {{grade}}**
Security {{sec}}/40 · Performance {{perf}}/25 · ImageSize {{size}}/20 · Reliability {{rel}}/15

**Stack:** {{language}} ({{package_manager}}){{ · framework_hint if not unknown}}{{ · native deps: <list> → alpine 비추천 if has_native_deps}}

---

## 🔴 Critical

{{for each critical finding}}
{{idx}}. **[{{rule_id}}] {{rule_title}}** — `{{path}}:{{line}}`
   > {{message}}{{ · 개선: <hint> if applicable}}
{{endfor}}

{{omit section if no critical findings}}

## 🟠 Major

{{for each major finding}}
{{idx}}. **[{{rule_id}}] {{rule_title}}** — `{{path}}:{{line}}`
   > {{message}}
{{endfor}}

## 🟡 Minor

{{for each minor finding}}
{{idx}}. **[{{rule_id}}] {{rule_title}}** — `{{path}}:{{line}}`
   > {{message}}
{{endfor}}

## ℹ️ Info (감점 없음)

{{for each info finding}}
- {{rule_id}}: {{message}}
{{endfor}}

---

## 📦 권장 .dockerignore

{{if .dockerignore missing or incomplete, show preset from dockerignore-base.md}}

```dockerignore
{{content}}
```

{{omit section if .dockerignore is complete}}

---

## ✨ 제안 Dockerfile

{{full improved Dockerfile from presets-{lang}.md, adapted to user's build commands}}

```dockerfile
{{content}}
```

---

## 🔀 Diff (요약)

```diff
{{unified diff between original and proposed}}
```

---

{{intent_footer}}
~~~

**intent_footer 분기 (의도별):**

- `optimize` (기본):
  > **참고**: {{auto-decisions: 베이스 이미지 변경, 네이티브 모듈 경고 등}}
  >
  > 아래 선택지에서 적용 방식을 골라주세요 (스킬이 `AskUserQuestion` 호출).

- `review`:
  > 위 분석은 리뷰 전용입니다. 적용을 원하시면 "최적화해줘"로 다시 요청해주세요.
  > (이 모드에서는 `AskUserQuestion`을 호출하지 않습니다.)

- `security`:
  > **참고**: {{auto-decisions}}
  >
  > 아래 선택지에서 적용 범위를 골라주세요 (스킬이 `AskUserQuestion` 호출).

`AskUserQuestion` 호출 후의 옵션 구성은 `SKILL.md` 워크플로우 [9] 단계를 따른다.

---

## 다중 Dockerfile 통합 요약

분석한 Dockerfile이 2개 이상일 때 마지막에 부착:

~~~markdown
---

# 📊 통합 요약

| 파일 | 점수 | 심각도 상위 이슈 |
|---|---|---|
{{for each dockerfile}}
| `{{path}}` | {{total}} ({{grade}}) | {{top 2 finding rule_ids}} |
{{endfor}}

가장 시급한 파일: `{{lowest_score_path}}` ({{reason}})
~~~

---

## 디자인 원칙 (LLM에게)

1. 이모지는 심각도 시각화에만. 본문은 깔끔한 텍스트.
2. 룰 ID 항상 노출 (`DFO-SEC-001` 형식).
3. 라인 번호 포함 (`Dockerfile:14`).
4. 개선 Dockerfile은 풀버전 우선, diff는 보조.
5. 자동 결정 항목은 마지막에 사유 명시 ("bcrypt 때문에 alpine 비추천").
6. 사용자 환경 가정 금지 ("당신의 ECS에서…" 같은 추정 표현 금지).
7. **사용자가 명시 승인하기 전까지 파일을 만지지 않는다.**
