---
name: oss-tour
description: >
  Progressive open-source repo learning tour. Use when the user wants to learn,
  explore, or understand an unfamiliar codebase/repo — triggers on "이 레포 학습",
  "이 오픈소스 구조 파악", "코드베이스 분석해줘", "이 프로젝트 어떻게 생겼어",
  "learn this repo", "explain this codebase". Produces layered maps (repo → folder
  → core module) with size-based priorities and a recommended reading order.
  Answers in Korean by default.
---

# OSS Tour — 오픈소스 레포 점진 학습법

목표: 거대 레포를 "전부 읽기"가 아니라 **지도 → 패턴 → 중심 → 흐름** 순서로 좁혀가며 학습한다.
각 단계 결과를 사용자에게 보여주고, 사용자가 궁금한 지점을 고르면 그쪽으로 파고든다 (한 번에 다 하지 않는다).

## 원칙

- 단계마다 출력은 **표 + 계층 트리** 로 압축. 파일 덤프 금지.
- **크기·커밋수·의존성 방향** 같은 측정값으로 우선순위를 정한다. 감으로 정하지 않는다.
- 패턴 하나 파악하면 반복 적용한다 (프랙탈 구조 활용) — 어댑터 하나 이해 = 어댑터 전부 이해.
- 각 단계 끝에 "다음 어디 팔까?" 선택지를 제시한다.
- 한국어로 답한다.

## 단계

### 1단계: 신원 + 규모 측정

무엇인지, 얼마나 큰지부터. README 첫 단락 + 아래 측정:

```bash
# 규모: 패키지 수 / 커밋 수 / 기여자 수
find . -name "package.json" -not -path "*/node_modules/*" -maxdepth 3 | wc -l   # JS 모노레포
git log --oneline | wc -l
git log --format='%an' | sort -u | wc -l
# 생태계 감지: package.json / go.mod / Cargo.toml / pyproject.toml / pom.xml
ls package.json go.mod Cargo.toml pyproject.toml 2>/dev/null
# 모노레포 감지: pnpm-workspace.yaml / turbo.json / nx.json / lerna.json / Cargo workspace
```

출력: 한 줄 정체성 + 규모 숫자 3개. "겁먹을 규모인가 아닌가" 판정.

### 2단계: 최상위 지도

```bash
ls -d */
```

폴더들을 **기능군으로 묶어서** 지도화 (알파벳순 나열 금지):

- 두뇌/코어 — 핵심 로직
- 어댑터/플러그인 — 교체 가능 구현체 (개수 세기: `for d in ...; do ls -d $d/*/ | wc -l; done`)
- 제품/앱 — CLI, UI, 서버
- 개발 자료 — examples, docs, e2e, scripts

### 3단계: 아키텍처 패턴 판정

레포 전체를 관통하는 설계 원칙 하나를 찾는다. 흔한 패턴:

- **core 계약 + 어댑터 구현** (플러그블): core가 인터페이스, 폴더별 구현, 사용자는 골라 설치
- **레이어드**: api → service → domain → infra
- **플러그인 버스**: 작은 코어 + 훅/이벤트로 확장
- **단일 앱**: 그냥 하나의 응용

판정 근거 제시: 어댑터 패키지의 package.json 의존성 방향 확인 (`구현 → core` 단방향인가), 이름 규칙 (`@scope/thing-provider` 꼴), 공통 base 클래스 존재.

이 단계에서 "왜 패키지를 쪼갰나"도 설명 (의존성 격리 / 버전 독립 / 기여 경계 / 설치 선택).

### 4단계: 중심 모듈 해부

가장 중요한 패키지(보통 core) 내부로:

```bash
ls -d packages/core/src/*/ | xargs -n1 basename
du -sh packages/core/src/*/ | sort -rh | head -15   # 크기 = 중요도 근사
```

폴더들을 다시 기능군으로: **실행 파이프라인 / 능력(꽂는 것) / 계약(어댑터 인터페이스) / 인프라 횡단 / 신규 방향**.
크기 상위 2-3개 = 프레임워크 본체. 여기가 진짜 학습 대상.

### 5단계: 실행 흐름 추적

정적 지도 다음은 동적 흐름. 대표 유스케이스 하나 골라 엔트리포인트부터 추적:

- 엔트리: main export, CLI entry, 서버 라우트
- 흐름을 한 줄 파이프라인으로: `A → B → C → D`
- 이때 Explore 서브에이전트 활용 (파일 덤프를 메인 컨텍스트에 안 실음)

### 6단계: 개발 규약 + 최근 방향

- `AGENTS.md` / `CLAUDE.md` / `CONTRIBUTING.md` / `.claude/` — 레포가 스스로 말하는 작업법
- 테스트 전략 (어디에, 어떤 러너, 우선순위 규칙)
- 최근 커밋 몰리는 곳 = 프로젝트가 가는 방향:

```bash
git log --since="3 months ago" --name-only --format= | cut -d/ -f1-2 | sort | uniq -c | sort -rn | head -10
```

### 마무리: 읽기 순서 추천

전 단계 종합해서 **"어디부터 읽어라" 3-5개 순서** 제시. 근거 포함.
예: "① mastra/(등록 구조) → ② agent/(최대 모듈) → ③ loop/(실행 엔진)".

## 안티패턴

- 한 턴에 6단계 전부 실행 — 금지. 사용자 질문 따라 진행.
- 파일 내용 통째로 인용 — 요약만.
- 측정 없이 "아마 이게 중요할 것" — du/커밋수로 확인.
- examples/ 부터 읽기 — 겉핥기됨. 지도 먼저.
