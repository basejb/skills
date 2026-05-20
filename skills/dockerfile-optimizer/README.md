# dockerfile-optimizer

Dockerfile을 **빌드 속도·이미지 크기·보안·배포 안정성** 4축으로 분석하고 개선안을 제안하는 Claude Code 스킬.

`Dockerfile 점검해줘` 한 줄이면 점수가 매겨진 리포트와 적용 가능한 개선 Dockerfile이 채팅에 출력된다. **명시 승인 전까지는 어떤 파일도 수정하지 않는다.**

---

## 무엇을 하는가

- Dockerfile을 정적 분석해 24개 룰(보안 8 + 성능 5 + 크기 5 + 안정성 6)로 진단
- 패키지 매니저·네이티브 의존성·프레임워크를 lockfile에서 자동 감지
- 사용자 스택에 맞춘 multi-stage Dockerfile 모범안 + diff 생성
- `.dockerignore` 부재 시 언어별 권장 내용 제시
- 다중 Dockerfile 레포에서는 통합 요약 표 출력

**하지 않는 일:**

- `docker build` / `docker run` 등 실제 실행
- 이미지 layer 분석 (dive 등)
- 취약점 스캔 (trivy 등)
- 동의 없는 파일 자동 수정

---

## 사용법

### 자동 발동 (트리거)

Dockerfile이 있는 디렉토리에서 다음과 같이 발화하면 스킬이 자동 발동:

| 의도       | 발화 예                                                                | 동작                                 |
| ---------- | ---------------------------------------------------------------------- | ------------------------------------ |
| **최적화** | "Dockerfile 점검해줘", "최적화해줘", "이미지 크기 줄여줘", "빌드 느려" | 리포트 + 개선 Dockerfile + 적용 안내 |
| **리뷰만** | "Dockerfile 리뷰만 해줘", "점검만"                                     | 리포트만 출력, 적용 안내 생략        |
| **보안**   | "도커 보안 점검", "root 사용 경고"                                     | Security 룰 우선, 보안 위주 개선안   |

### 적용

분석이 끝나면 스킬이 **선택지를 띄운다** (`AskUserQuestion`). 클릭만으로 진행:

| 옵션 | 동작 |
| --- | --- |
| **전체 적용 (Recommended)** | Dockerfile + `.dockerignore` 모두 수정 |
| **Dockerfile만 적용** | `.dockerignore`는 그대로 |
| **.dockerignore만 만들기** | Dockerfile은 그대로 |
| **선택 적용 — 번호로 지정** | 후속 메시지로 finding 번호 (`1, 3`) 전달 |
| **적용 안 함 (리뷰만)** | 어떤 파일도 수정하지 않고 종료 |

선택지가 뜨지 않거나 응답하지 않으면 **어떤 파일도 수정되지 않는다**.

### 명시 호출

자동 발동이 안 되거나 명시적으로 실행하려면:

```
/basejb:dockerfile-optimizer
```

---

## 분석 항목

### Security (40점)

USER 미설정·root 사용·시크릿 COPY·시크릿스러운 ARG/ENV·`ADD <URL>` 무체크섬·`latest` 태그·`apt --no-install-recommends` 누락·`curl | sh`

### Performance (25점)

의존성 설치 전 `COPY . .`·lockfile 무시·연속 RUN 미결합·apt cache 미정리·BuildKit cache mount 미사용

### ImageSize (20점)

multi-stage 미사용·full 베이스 이미지·런타임에 devDependencies·`.dockerignore` 부재·레이어 임시파일 미정리

### Reliability (15점)

CMD/ENTRYPOINT shell form·WORKDIR 미설정·server-like CMD에 EXPOSE 누락·HEALTHCHECK(info)·표준 env var 누락

### 점수 산식

```
카테고리 점수 = max(0, 배점 - sum(감점))
총점 = 4 카테고리 합 (0~100)
등급 = 90+ A · 80+ B · 70+ C · 60+ D · <60 F
```

심각도별 감점: `critical -10` / `major -5` / `minor -2` / `info 0`

---

## 지원 스택

자동 감지(`scripts/detect-stack.sh` 통해 lockfile 우선순위 판정):

| 언어    | 패키지 매니저     | 감지 파일                                            |
| ------- | ----------------- | ---------------------------------------------------- |
| Node.js | npm / pnpm / yarn | `package-lock.json` / `pnpm-lock.yaml` / `yarn.lock` |
| Python  | pip / poetry / uv | `requirements.txt` / `poetry.lock` / `uv.lock`       |
| Go      | go modules        | `go.mod`                                             |

**프레임워크 힌트** (자동 인식): NestJS, Next.js, Express, Fastify, FastAPI, Django, Flask

**네이티브 의존성**(`bcrypt`·`sharp`·`canvas`·`node-gyp` 등) 감지 시 alpine 추천 자동 비활성화.

---

## Requirements

| 도구                                               | 필수 여부 | 용도                                                     |
| -------------------------------------------------- | --------- | -------------------------------------------------------- |
| `bash`                                             | 필수      | 스택 감지 스크립트 (`scripts/detect-stack.sh`)           |
| `grep`, `find`                                     | 필수      | 표준 유닉스 도구                                         |
| [`hadolint`](https://github.com/hadolint/hadolint) | **선택**  | 설치돼 있으면 추가 룰 점검 (점수 미반영, 별도 섹션 부착) |

### hadolint 설치 (선택)

```bash
# macOS
brew install hadolint

# Linux (binary 다운로드)
curl -L https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 \
  -o /usr/local/bin/hadolint && chmod +x /usr/local/bin/hadolint
```

미설치 시 정상 동작하며 룰 기반 점검만 수행. 1회만 설치 안내 출력.

---

## 출력 예시

```markdown
# Dockerfile Review — `apps/api/Dockerfile`

**Score: 58 / 100 — F**
Security 20/40 · Performance 18/25 · ImageSize 5/20 · Reliability 15/15

**Stack:** Node.js (pnpm) · NestJS 추정 · native deps: bcrypt → alpine 비추천

## 🔴 Critical

1. **[DFO-SEC-001] root 사용자로 실행** — `Dockerfile:14`
   > USER 지시어 없음. 컨테이너 escape 시 권한 상승 위험.

## 🟠 Major

3. **[DFO-SIZE-001] multi-stage 미사용** — `Dockerfile:1`
   > 단일 스테이지로 빌드 도구가 런타임 이미지에 잔존. 예상 절감: 200~400MB.

## ✨ 제안 Dockerfile

\`\`\`dockerfile
FROM node:20-slim AS builder
...
\`\`\`

↓ 스킬이 적용 방식 선택지를 띄움 (전체 / Dockerfile만 / .dockerignore만 / 번호 지정 / 안 함)
```

---

## 디렉토리 구조

```
dockerfile-optimizer/
├── SKILL.md                       # 진입점 (트리거 · 워크플로우 · Rule Index)
├── scripts/
│   └── detect-stack.sh            # lockfile 기반 스택 자동 감지
├── references/
│   ├── rules-security.md          # 보안 룰 8개
│   ├── rules-performance.md       # 성능 룰 5개
│   ├── rules-image-size.md        # 크기 룰 5개
│   ├── rules-reliability.md       # 안정성 룰 6개
│   ├── presets-nodejs.md          # npm / pnpm / yarn / Next.js / native 변형
│   ├── presets-python.md          # pip / poetry / uv / Django 변형
│   ├── presets-go.md              # distroless / scratch / private / CGO 변형
│   ├── dockerignore-base.md       # 언어별 권장 .dockerignore
│   └── report-template.md         # 리포트 마크다운 템플릿
└── tests/
    ├── test-detect-stack.sh       # detect-stack 회귀 테스트 (20 케이스)
    ├── fixtures/                  # 11개 시연용 Dockerfile
    └── expected/                  # 사람이 읽는 기대 결과
```

---

## 시연

설치 후 fixture로 감 잡기:

```bash
# 위반 종합 케이스 (점수 30~50 기대)
cd "$(claude plugin path basejb)/skills/dockerfile-optimizer/tests/fixtures/nodejs-bad"
# 새 Claude Code 세션 → "Dockerfile 점검해줘"

# 모범 답안 (점수 95+ 기대)
cd "$(claude plugin path basejb)/skills/dockerfile-optimizer/tests/fixtures/nodejs-good"
# → "Dockerfile 점검해줘"

# 네이티브 의존성 분기 (alpine 추천 비활성화)
cd "$(claude plugin path basejb)/skills/dockerfile-optimizer/tests/fixtures/nodejs-native"
# → "Dockerfile 점검해줘"
```

`detect-stack.sh` 단독 회귀 테스트:

```bash
./tests/test-detect-stack.sh
# Total: 20 | Pass: 20 | Fail: 0
```

---

## 룰 추가 / 커스터마이즈

새 룰을 추가하려면:

1. 해당 카테고리의 `references/rules-<category>.md`에 룰 추가
   - 형식: `## DFO-<CAT>-NNN: <title>` + Severity / Deduction / Detection / Why / Bad / Good
2. `SKILL.md`의 **Rule Index** 표에 한 줄 추가
3. `tests/fixtures/<rule-id>-bad/Dockerfile` 위반 예 + `<rule-id>-good/Dockerfile` 정상 예
4. `tests/expected/<rule-id>-*.md`에 기대 결과 명시

---

## 한계

- LLM 기반 룰 매칭이라 출력이 완전 결정적이지 않음 (룰 ID는 결정적, 표현은 흔들릴 수 있음)
- Java/Spring, Ruby, .NET 미지원 (v2 후보)
- 실제 빌드 시간·이미지 크기를 측정하지 않음 (정적 분석)
- 취약점 스캔(trivy) 미통합

---

## 출처 / 라이선스

- **Author**: [@basejb](https://github.com/basejb) (직접 작성)
- **License**: MIT
- **Marketplace**: [basejb/skills](https://github.com/basejb/skills)
