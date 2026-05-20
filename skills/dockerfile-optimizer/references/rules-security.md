# Security Rules (DFO-SEC-*)

**Category:** Security
**Category budget:** 40 points
**Score formula:** `max(0, 40 - sum(deductions))`

각 룰은 SKILL.md의 룰 엔진이 발견 시 `findings[]`에 추가한다. 룰 ID는 출력에 반드시 노출한다.

---

## DFO-SEC-001: Container runs as root

**Severity:** critical
**Deduction:** -10

### Detection

- `USER` directive가 Dockerfile 어디에도 없음
- 또는 마지막 `USER` 값이 비어 있음

### Why

컨테이너 탈출 시 호스트 권한 상승으로 이어진다. PID 1이 root로 실행되면 파일시스템과 Linux capability 공격 면이 크게 넓어진다. CIS Docker Benchmark 4.1은 반드시 non-root 사용자로 실행할 것을 요구한다.

### Bad

```dockerfile
FROM node:20-slim
WORKDIR /app
COPY . .
RUN npm ci
CMD ["node", "dist/main.js"]
```

### Good

```dockerfile
FROM node:20-slim
WORKDIR /app
COPY . .
RUN npm ci
RUN addgroup --system app && adduser --system --ingroup app app
USER app
CMD ["node", "dist/main.js"]
```

### References

- `CIS Docker Benchmark v1.6.0 — 4.1`
- `https://docs.docker.com/engine/security/`

---

## DFO-SEC-002: Container explicitly runs as root

**Severity:** critical
**Deduction:** -10

### Detection

- 마지막 `USER` 지시어가 `USER root` 또는 `USER 0`임

### Why

명시적으로 root를 사용하는 것은 SEC-001의 모든 위험에 더해 의도적 선택임을 나타낸다. 빌드 시에만 root가 필요하다면, 멀티 스테이지 빌드에서 runner 스테이지를 non-root로 분리하면 된다.

### Bad

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y nginx
USER root
CMD ["nginx", "-g", "daemon off;"]
```

### Good

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y --no-install-recommends nginx \
    && rm -rf /var/lib/apt/lists/*
RUN useradd -r -s /sbin/nologin nginx-app || true
USER nginx-app
CMD ["nginx", "-g", "daemon off;"]
```

---

## DFO-SEC-003: Secret files copied into image

**Severity:** critical
**Deduction:** -10

### Detection

- `COPY` 인자가 다음 패턴과 일치: `.env`, `*.pem`, `id_rsa`, `id_ed25519`, `credentials.json`, `*.key`, `service-account*.json`
- 또는 `COPY . .` 사용 AND `.dockerignore`에 `.env` 누락

### Why

이미지 레이어는 불변(immutable)이다. 한 번이라도 커밋된 시크릿은 `docker history`와 푸시된 레지스트리에 영구적으로 남는다. BuildKit 시크릿(`RUN --mount=type=secret`)을 사용하거나, 런타임 환경 변수로 주입해야 한다.

### Bad

```dockerfile
# Bad example 1: secret file directly copied
COPY .env /app/.env

# Bad example 2: wildcard copy without .dockerignore exclusion
# .dockerignore does not list .env
COPY . .
```

### Good

```dockerfile
# BuildKit secret mount: 레이어에 잔류하지 않음
RUN --mount=type=secret,id=env_file \
    cp /run/secrets/env_file /tmp/.env \
    # use it, then it's gone after the layer
    && rm /tmp/.env
# 또는 .dockerignore에 .env 패턴을 추가하고 런타임에 -e 플래그로 주입
```

---

## DFO-SEC-004: Secret-like ARG or ENV declarations

**Severity:** major
**Deduction:** -5

### Detection

- `ARG` 또는 `ENV` 변수 이름이 다음 패턴과 일치: `*_KEY`, `*_TOKEN`, `*_SECRET`, `*PASSWORD*`, `*_API_KEY`, `AWS_*`, `*_PRIVATE_KEY`
- 제외: `*_PATH`, `*_KEYRING`, `*_TOKEN_PATH` (경로/설정 성격의 변수)

### Why

`ARG` 값은 `docker history`로 노출된다. `ENV`는 모든 자식 프로세스에 상속되고 이미지 메타데이터에 저장된다. 빌드 타임 시크릿은 BuildKit `--mount=type=secret`을 사용하고, 런타임 시크릿은 `-e` 플래그나 시크릿 매니저로 주입해야 한다.

### Bad

```dockerfile
ARG AWS_SECRET_ACCESS_KEY
ENV DATABASE_PASSWORD=changeme
```

### Good

```dockerfile
# BuildKit secret으로 빌드 타임 자격증명 처리
RUN --mount=type=secret,id=aws_creds \
    aws s3 cp s3://bucket/file . --profile $(cat /run/secrets/aws_creds)
# 런타임 시크릿은 docker run -e 또는 시크릿 매니저로 주입
```

---

## DFO-SEC-005: ADD <URL> without checksum

**Severity:** major
**Deduction:** -5

### Detection

- `ADD https?://...` 패턴이 존재 AND 동일 `RUN`에 `sha256sum -c` / `gpg --verify` 등 체크섬 검증 없음

### Why

다운로드 대상이 변경되면 빌드 재현성이 깨지고 공급망 공격 위험이 생긴다. `COPY` + 별도 다운로드 + 검증 단계로 분리해야 한다.

### Bad

```dockerfile
ADD https://example.com/installer.sh /tmp/installer.sh
RUN bash /tmp/installer.sh
```

### Good

```dockerfile
RUN curl -fsSL https://example.com/installer.sh -o /tmp/installer.sh \
    && echo "EXPECTED_SHA256  /tmp/installer.sh" | sha256sum -c - \
    && bash /tmp/installer.sh \
    && rm /tmp/installer.sh
```

---

## DFO-SEC-006: Base image tag is `latest` or missing

**Severity:** major
**Deduction:** -5

### Detection

- `FROM image` (태그 없음) 또는 `FROM image:latest`

### Why

`latest` 태그는 가변(mutable)이다. 빌드 재현성이 깨지고, 보안 패치 타이밍을 제어할 수 없게 된다. SHA256 다이제스트 또는 명시적 버전·마이너 버전으로 고정해야 한다.

### Bad

```dockerfile
FROM node
FROM python:latest
```

### Good

```dockerfile
FROM node:20.11-slim
# 또는 다이제스트 고정
FROM node:20.11-slim@sha256:abcd...
```

---

## DFO-SEC-007: apt-get without --no-install-recommends

**Severity:** minor
**Deduction:** -2

### Detection

- `apt-get install` 라인에 `--no-install-recommends` 플래그 없음

### Why

추천 패키지(recommends)는 보안 공격 면과 이미지 크기를 모두 증가시킨다. 필요한 패키지만 명시적으로 설치해야 한다.

### Bad

```dockerfile
RUN apt-get update && apt-get install -y python3
```

### Good

```dockerfile
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 \
    && rm -rf /var/lib/apt/lists/*
```

---

## DFO-SEC-008: curl ... | sh pattern

**Severity:** major
**Deduction:** -5

### Detection

- `curl ... | sh`, `curl ... | bash`, `wget ... | sh`, `wget -O- ... | bash` 등의 패턴

### Why

다운로드한 내용을 무결성 검증 없이 즉시 실행한다. MITM 공격이나 원본 서버 침해 시 임의 코드가 실행된다. 다운로드 → 검증 → 실행으로 단계를 분리해야 한다.

### Bad

```dockerfile
RUN curl -sSL https://get.example.io | sh
```

### Good

```dockerfile
RUN curl -fsSL https://get.example.io -o /tmp/install.sh \
    && echo "EXPECTED_SHA256  /tmp/install.sh" | sha256sum -c - \
    && sh /tmp/install.sh \
    && rm /tmp/install.sh
```

---
