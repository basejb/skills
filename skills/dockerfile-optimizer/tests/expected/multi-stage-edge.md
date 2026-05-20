# Expected: multi-stage-edge

## must_detect
- DFO-SEC-001 (USER 없음)
- DFO-SIZE-003 (`FROM deps AS final`로 dev deps이 그대로 따라감)

## notes
- 멀티스테이지가 있어도 final stage가 builder를 inherit하면 dev deps이 남음을 검출해야 함
