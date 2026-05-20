# Expected: nodejs-native

## detect-stack output
- has_native_deps: true (bcrypt 감지)

## must_detect
- DFO-SEC-001 + DFO-SEC-002 (USER root)
- DFO-SIZE-001, DFO-SIZE-003, DFO-SIZE-004
- DFO-PERF-001, DFO-PERF-002

## must_not_detect
- DFO-SIZE-002 — **핵심 검증**: native deps 있으므로 alpine 추천 비활성화

## notes
- 개선 Dockerfile 제안 시 alpine 사용 금지, slim 권장
- 리포트 stack 라인에 "native deps: bcrypt → alpine 비추천" 명시돼야 함
