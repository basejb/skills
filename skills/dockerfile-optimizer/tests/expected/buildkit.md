# Expected: buildkit

## must_detect
- DFO-PERF-005 (BuildKit 사용 가능한데 --mount=type=cache 미사용)
- DFO-SIZE-004 (.dockerignore 없음 — 이 fixture에선 일부러 생략)

## must_not_detect
- DFO-SEC-001 (USER node)
- DFO-PERF-001, DFO-PERF-002, DFO-SIZE-001, DFO-SIZE-003, DFO-REL-001
