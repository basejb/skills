# Expected: nodejs-good

## detect-stack output
- language: node
- package_manager: npm
- has_native_deps: false
- framework_hint: express

## must_detect
- (없음 또는 info만)

## must_not_detect
- DFO-SEC-001 (USER node 있음)
- DFO-PERF-001 (의존성 설치 후 COPY)
- DFO-PERF-002 (npm ci 사용)
- DFO-SIZE-001 (multi-stage)
- DFO-SIZE-002 (slim 사용)
- DFO-SIZE-003 (--omit=dev)
- DFO-SIZE-004 (.dockerignore 충분)
- DFO-REL-001 (exec form)

## score_range
- 95~100
