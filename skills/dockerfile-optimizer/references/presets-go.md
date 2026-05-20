# Go Dockerfile Presets

`language=go` 판정 시 사용. Go는 정적 바이너리 생성이 쉬워 scratch/distroless 활용이 매우 효과적이다.

---

## Multi-stage with distroless (권장 기본)

```dockerfile
# syntax=docker/dockerfile:1.7

FROM golang:1.22-alpine AS builder
WORKDIR /src

ENV CGO_ENABLED=0 \
    GOOS=linux

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -trimpath -ldflags="-s -w" -o /out/app ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /
COPY --from=builder /out/app /app
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/app"]
```

---

## Multi-stage with scratch (최소 크기)

```dockerfile
# syntax=docker/dockerfile:1.7

FROM golang:1.22-alpine AS builder
WORKDIR /src

ENV CGO_ENABLED=0 \
    GOOS=linux

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -trimpath -ldflags="-s -w" -o /out/app ./cmd/server

# CA certs 필요 시 builder에서 복사
FROM scratch
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /out/app /app
EXPOSE 8080
ENTRYPOINT ["/app"]
```

scratch는 shell·busybox 없음 → 디버깅 곤란. 프로덕션엔 distroless가 합리적.

---

## Private modules (GOPRIVATE) 변형

```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /src

ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOPRIVATE=github.com/myorg/*

RUN apk add --no-cache git openssh-client

# BuildKit secret으로 SSH key 주입
RUN --mount=type=ssh \
    --mount=type=cache,target=/go/pkg/mod \
    git config --global url."git@github.com:".insteadOf "https://github.com/" \
    && go env -w GOPRIVATE=$GOPRIVATE

COPY go.mod go.sum ./
RUN --mount=type=ssh \
    --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY . .
RUN go build -trimpath -ldflags="-s -w" -o /out/app ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /out/app /app
USER nonroot:nonroot
ENTRYPOINT ["/app"]
```

빌드: `DOCKER_BUILDKIT=1 docker build --ssh default -t myapp .`

---

## CGO 필요한 경우

```dockerfile
FROM golang:1.22 AS builder
WORKDIR /src

ENV CGO_ENABLED=1 \
    GOOS=linux

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -trimpath -ldflags="-s -w" -o /out/app ./cmd/server

# CGO는 glibc 필요 → distroless cc 사용
FROM gcr.io/distroless/cc-debian12:nonroot
COPY --from=builder /out/app /app
USER nonroot:nonroot
ENTRYPOINT ["/app"]
```
