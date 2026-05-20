# Performance Rules (DFO-PERF-*)

**Category:** Performance
**Category budget:** 25 points
**Score formula:** `max(0, 25 - sum(deductions))`

빌드 캐시 효율과 레이어 수에 집중한다. 점수보다 "왜 캐시가 깨지는가"의 설명이 사용자 가치가 크다.

---

## DFO-PERF-001: Source COPY before dependency install

**Severity:** major
**Deduction:** -5

### Detection

- `COPY . .` 또는 와일드카드 `COPY . /app`이 `RUN npm ci|install`, `RUN pnpm install`, `RUN pip install`, `RUN poetry install`, `RUN go mod download` 등 의존성 설치 명령보다 **앞에** 위치함

### Why

소스 파일 한 줄만 바뀌어도 `COPY . .` 레이어가 무효화되고, 그 이후의 의존성 설치 레이어 전체가 재실행된다. 패키지 매니페스트를 먼저 복사하고 의존성을 설치한 뒤 소스를 복사하면, 소스 변경 시 캐시가 설치 레이어까지만 유지된다.

### Bad

```dockerfile
WORKDIR /app
COPY . .
RUN npm ci
RUN npm run build
```

### Good

```dockerfile
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build
```

언어별 복사 대상 매니페스트:

- npm/pnpm/yarn: `package*.json`, `pnpm-lock.yaml`, `yarn.lock`
- pip: `requirements*.txt`
- poetry: `pyproject.toml`, `poetry.lock`
- uv: `pyproject.toml`, `uv.lock`
- go: `go.mod`, `go.sum`

---

## DFO-PERF-002: Install command does not respect lockfile

**Severity:** major
**Deduction:** -5

### Detection

패키지 매니저별 frozen 설치 명령을 사용하지 않는 경우:

| Manager | Required command |
|---|---|
| npm | `npm ci` |
| pnpm | `pnpm install --frozen-lockfile` |
| yarn | `yarn install --frozen-lockfile` |
| poetry | `poetry install --no-root --only main` (또는 `--without dev`) |
| uv | `uv sync --frozen --no-dev` |
| pip | `pip install --no-cache-dir -r requirements.txt` |
| go | `go mod download` (별도 단계) |

`npm install`, `pnpm install` (frozen 없음), `yarn install` (frozen 없음)은 위반으로 판정한다.

### Why

lockfile을 무시하는 설치 모드는 빌드마다 의존성 버전이 달라질 수 있다. CI/CD 재현성이 깨지고, 캐시 키 안정성도 손상된다.

### Bad

```dockerfile
COPY package.json ./
RUN npm install
```

### Good

```dockerfile
COPY package.json package-lock.json ./
RUN npm ci
```

---

## DFO-PERF-003: Consecutive RUN commands not combined

**Severity:** minor
**Deduction:** -2

### Detection

- 연속된 `RUN` 줄이 3개 이상 존재

### Why

레이어 수가 많을수록 이미지 크기와 push/pull 시간이 증가한다. 논리적으로 관련된 명령은 `&&`로 이어 단일 레이어로 합쳐야 한다.

### Bad

```dockerfile
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN rm -rf /var/lib/apt/lists/*
```

### Good

```dockerfile
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl git \
    && rm -rf /var/lib/apt/lists/*
```

---

## DFO-PERF-004: apt-get update without cache cleanup

**Severity:** minor
**Deduction:** -2

### Detection

- `apt-get update` 라인 이후 동일한 `RUN` 블록 또는 바로 뒤 `RUN`에 `rm -rf /var/lib/apt/lists/*`가 없음

### Why

apt 캐시(`/var/lib/apt/lists/`)가 이미지 레이어에 남으면 수 MB~수십 MB가 낭비된다. 설치와 캐시 정리를 같은 레이어에서 수행해야 최종 이미지에 캐시가 포함되지 않는다.

### Bad

```dockerfile
RUN apt-get update && apt-get install -y curl
```

### Good

```dockerfile
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
```

---

## DFO-PERF-005: BuildKit cache mount not used for large deps

**Severity:** minor (informational)
**Deduction:** -2 (Dockerfile이 200줄을 초과하거나 모노레포 빌드 컨텍스트인 경우에만 적용; 그 외에는 info-only)

### Detection

- BuildKit 사용 환경(`# syntax=docker/dockerfile:1.x` 헤더 또는 `DOCKER_BUILDKIT=1` 명시) AND
- `RUN npm ci`, `RUN pnpm install`, `RUN apt-get install`, `RUN go mod download` 등에 `--mount=type=cache`가 없음

### Why

캐시 마운트는 빌드 캐시가 무효화되더라도 패키지 다운로드를 재사용한다. 대형 모노레포에서는 빌드 시간이 절반으로 줄어드는 사례도 있다.

### Good (npm)

```dockerfile
# syntax=docker/dockerfile:1.7
RUN --mount=type=cache,target=/root/.npm \
    npm ci
```

### Good (pnpm)

```dockerfile
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile
```
