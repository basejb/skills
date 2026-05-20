# Image Size Rules (DFO-SIZE-*)

**Category:** ImageSize
**Category budget:** 20 points
**Score formula:** `max(0, 20 - sum(deductions))`

multi-stage, 베이스 이미지, devDependencies, .dockerignore의 4축을 본다.

---

## DFO-SIZE-001: Multi-stage build not used (build tools leak to runtime)

**Severity:** major
**Deduction:** -5

### Detection

- `FROM ... AS <name>` 스테이지 선언이 전혀 없음 AND
- 다음 중 하나 이상 존재: `RUN npm run build`, `RUN pnpm build`, `RUN yarn build`, `RUN go build`, `RUN poetry build`, `RUN pip wheel`, `RUN make`, `RUN cargo build`

### Why

단일 스테이지 이미지에는 빌드 도구, dev 의존성, 소스 코드가 그대로 남는다. 멀티 스테이지로 아티팩트만 복사하면 이미지 크기를 50~80% 줄일 수 있다.

### Bad

```dockerfile
FROM node:20-slim
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build
CMD ["node", "dist/main.js"]
```

### Good

```dockerfile
FROM node:20-slim AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-slim AS runner
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY --from=builder /app/dist ./dist
USER node
CMD ["node", "dist/main.js"]
```

---

## DFO-SIZE-002: Full base image used (slim/alpine candidate)

**Severity:** minor
**Deduction:** -2

### Detection

- `FROM` 태그가 다음에 해당: `node:NN`, `python:N.NN`, `golang:N.NN`, `ruby:N.N`, `openjdk:NN` (slim/alpine 접미사 없음 = full debian 기반)
- **예외**: `scripts/detect-stack.sh`가 `has_native_deps == true`를 보고하면 이 룰을 **비활성화**한다 (alpine은 musl 기반이라 native 빌드 실패; slim도 ABI 불일치 가능)

### Why

full 이미지는 1 GB 이상, slim은 200 MB 미만, alpine은 50 MB 미만이다. 불필요한 시스템 패키지를 제거하면 보안 공격 면도 함께 줄어든다.

### Bad

```dockerfile
FROM node:20
```

### Good (native 의존성 없음)

```dockerfile
FROM node:20-slim
# 또는 alpine 빌드가 검증된 경우
FROM node:20-alpine
```

### Good (native 의존성 있음 — bcrypt/sharp 등)

```dockerfile
FROM node:20-slim
# alpine 비추천: musl libc 호환성 문제
# 보고서에 반드시 "native deps: bcrypt → alpine 비추천" 표시
```

---

## DFO-SIZE-003: devDependencies present in runtime stage

**Severity:** major
**Deduction:** -5

### Detection

단일 스테이지이거나 마지막 스테이지에서 아래 조건 중 하나라도 해당되는 경우:

- npm: `npm ci` 또는 `npm install`만 있고 `--omit=dev` / `--production` 없음
- pnpm: `pnpm install`만 있고 `--prod` 없음
- poetry: `poetry install`만 있고 `--only main` / `--without dev` 없음
- uv: `uv sync`만 있고 `--no-dev` 없음

### Why

TypeScript, eslint, jest, webpack 등 dev 의존성이 런타임 이미지에 포함되면 수백 MB가 낭비되고 보안 공격 면이 넓어진다.

### Bad

```dockerfile
FROM node:20-slim
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
CMD ["node", "dist/main.js"]
```

### Good (multi-stage)

```dockerfile
FROM node:20-slim AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-slim AS runner
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY --from=builder /app/dist ./dist
CMD ["node", "dist/main.js"]
```

---

## DFO-SIZE-004: .dockerignore missing or incomplete

**Severity:** major
**Deduction:** -5

### Detection

- Dockerfile이 위치한 디렉토리 또는 상위 디렉토리에 `.dockerignore`가 없음
- 또는 존재하지만 아래 항목이 누락됨:
  - 공통: `.git`, `*.log`, `.DS_Store`
  - Node.js: `node_modules`, `dist`, `coverage`
  - Python: `__pycache__`, `*.pyc`, `.venv`, `dist`
  - Go: `bin`, `dist`
  - 전체: `.env`, `.env.*` (단, `!.env.example` 예외 허용)

### Why

빌드 컨텍스트가 크면 (1) 업로드 시간이 늘어나고 (2) 캐시 키 안정성이 떨어지고 (3) 시크릿이나 불필요한 파일이 이미지에 유입될 수 있다.

권장 `.dockerignore` 예시는 `references/dockerignore-base.md`를 참고한다.

### Bad

빌드 컨텍스트 루트에 `.dockerignore` 파일이 없거나, 다음과 같이 핵심 항목이 빠진 경우:

~~~dockerignore
.git
node_modules
~~~

(.env, *.log, dist 등 추가 항목 미명시 → 시크릿/노이즈 누출 위험)

### Good

권장 .dockerignore (Node.js 프로젝트 예시):

~~~dockerignore
.git
.gitignore
.DS_Store
.vscode
.idea
*.log
.env
.env.*
!.env.example
node_modules
dist
coverage
.next
.turbo
~~~

언어별 전체 권장 내용은 `references/dockerignore-base.md` 참고.

---

## DFO-SIZE-005: No cleanup after package installs in same layer

**Severity:** minor
**Deduction:** -2

### Detection

- `apt-get install` / `apk add` / `yum install` / `dnf install` 이후 같은 `RUN`에 캐시 정리 없음
- `pip install`에 `--no-cache-dir` 없음
- `wget` / `curl`로 내려받은 임시 파일이 같은 `RUN`에서 삭제되지 않음

### Why

레이어는 생성 시점에 내용이 확정된다. 이후 레이어에서 삭제해도 앞 레이어의 크기는 줄어들지 않는다. 설치와 정리를 반드시 같은 `RUN`에서 수행해야 한다.

### Good

```dockerfile
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir -r requirements.txt
```
