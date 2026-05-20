# Expected: nodejs-bad

## detect-stack output
- language: node
- package_manager: npm  (no lockfile, only package.json)
- has_native_deps: false
- framework_hint: express

## must_detect
- DFO-SEC-001 (USER 없음 → root)
- DFO-PERF-001 (COPY . . 이 npm install 전)
- DFO-PERF-002 (npm install, lockfile 미존중)
- DFO-SIZE-001 (multi-stage 없음)
- DFO-SIZE-002 (node:20 full)
- DFO-SIZE-003 (devDeps 포함된 채 runtime, npm install 사용)
- DFO-SIZE-004 (.dockerignore 없음)
- DFO-REL-001 (CMD shell form)
- DFO-REL-006 (NODE_ENV 미설정)

## must_not_detect
- DFO-SEC-002 (USER root 명시 아님)
- DFO-SEC-006 (`node:20`은 latest도 아니고 누락도 아님)
- DFO-PERF-003 (연속 RUN이 2개라 임계 3개 미만)

## score_range
- 30~50

## notes
- DFO-SEC-003은 `.env`를 직접 COPY하지 않으므로 명시적으로는 미해당. 단 `COPY . .` + `.dockerignore` 부재 결합 시 LLM이 SEC-003으로 판단해도 무방 (false positive로 보지 않음)
