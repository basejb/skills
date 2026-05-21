# Smoke Test — 5단계 흐름 수동 검증

자동 테스트(`test-*.sh`)는 스크립트의 단위 동작만 검증한다. 이 체크리스트는 실제 학습 세션을 한 번 통과하면서 5단계 + 노트 누적 + INDEX 동기화가 모두 작동하는지 손으로 확인한다.

## 준비

- [ ] `~/learning-notes/` 가 비어 있거나, 백업
- [ ] 모든 단위 테스트 통과 확인:
  ```bash
  bash skills/learning-companion/tests/test-new-note.sh
  bash skills/learning-companion/tests/test-update-index.sh
  bash skills/learning-companion/tests/test-list-in-progress.sh
  ```

## 시나리오 A: 신규 학습 (5단계 모두)

대상 자료: https://www.anthropic.com/research/building-effective-agents (또는 짧은 글)

- [ ] Claude에게: "이 문서 같이 학습하자 <URL>"
- [ ] `~/learning-notes/YYYY-MM-DD-<slug>.md` 생성 확인
- [ ] `INDEX.md`의 In Progress에 항목 등장 확인
- [ ] **Stage 1**: `## Source` 섹션에 한 줄 요약 + 핵심 개념 3–7 채워졌나
- [ ] **Stage 2**: `## Concepts` 섹션에 개념별로 인용/내말로/비유/반례 4요소 모두 있나
- [ ] **Stage 3**: 퀴즈가 **한 문항씩** 출제되었나 (한꺼번에 5개가 아니라)
- [ ] **Stage 3**: 채점에 원문 인용이 포함되었나
- [ ] **Stage 4**: Reflection이 **사용자 1인칭**으로 적혔나
- [ ] **Stage 5**: Next 3개 항목 + INDEX Backlog에 동기화 확인
- [ ] 세션 종료 시 INDEX에서 In Progress → Completed 이동 확인

## 시나리오 B: 단계 진입점 (퀴즈만)

- [ ] "이 문서 퀴즈만 내줘 <URL>"
- [ ] 노트의 frontmatter `status: partial` 확인
- [ ] `## Quiz` 섹션만 채워지고 다른 섹션은 비어 있는지 확인
- [ ] INDEX의 In Progress에 들어가 있는지 (`partial`이라도 재개 가능)

## 시나리오 C: 이어 하기

- [ ] 시나리오 A의 세션을 Stage 3 중간에 중단 (사용자가 "그만"이라 발화)
- [ ] 새 대화에서: "지난번 학습 이어서"
- [ ] 스킬이 `list-in-progress.sh` 호출 → 후보 노트 목록 제시
- [ ] 사용자가 선택 → Stage 3부터 재개

## 시나리오 D: 동일 자료 재학습

- [ ] 시나리오 A 완료 후, 같은 URL을 다시 던짐
- [ ] 3지선다 ("이어 하기 / 새로 시작 / 그만두기") 프롬프트 확인
- [ ] "새로 시작" 선택 시 새 슬러그(또는 `-v2` 등)로 노트 분리

## 시나리오 E: 발동 안 해야 할 케이스

- [ ] "Agent가 뭐야?" → 스킬 발동 X, 일반 응답
- [ ] "이 코드베이스 onboarding 해줘" → 스킬 발동 X
- [ ] "<URL> 번역해줘" → 스킬 발동 X (단순 번역만)
