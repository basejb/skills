# Expected: multi-dockerfile-repo

## 동작 검증
- 스킬 실행 시 두 Dockerfile 모두 발견 → AskUserQuestion으로 디스앰비귀에이션 질문
- "전체"로 답하면 두 리포트 각각 + 통합 요약 표 출력
- 통합 요약에서 apps/api/가 가장 낮은 점수로 표기돼야 함
