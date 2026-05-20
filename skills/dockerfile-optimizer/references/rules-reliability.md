# Reliability Rules (DFO-REL-*)

**Category:** Reliability
**Category budget:** 15 points
**Score formula:** `max(0, 15 - sum(deductions))`

신호 처리, 작업 디렉토리, 환경 변수 표준 등 배포 시 흔히 문제 되는 항목.

---

## DFO-REL-001: CMD uses shell form

**Severity:** major
**Deduction:** -5

### Detection

- `CMD ` 다음이 `[`으로 시작하지 않음 (exec form은 JSON 배열 필수)
- 예: `CMD npm start`, `CMD node server.js`

### Why

shell form은 `/bin/sh -c "cmd"`로 감싸므로 PID 1이 sh가 된다. SIGTERM/SIGINT가 자식 프로세스에 전달되지 않아 graceful shutdown이 실패하고, ECS/Kubernetes는 결국 SIGKILL로 강제 종료한다. exec form은 명령을 PID 1로 직접 실행하여 시그널이 바로 도달한다.

### Bad

```dockerfile
CMD npm start
```

### Good

```dockerfile
CMD ["node", "dist/main.js"]
```

> 참고: exec form이더라도 `CMD ["npm", "start"]`는 npm이 시그널을 자식에게 포워딩하지 않는다. 가능하면 `node`를 직접 호출하는 것을 권장한다.

---

## DFO-REL-002: ENTRYPOINT uses shell form

**Severity:** minor
**Deduction:** -2

### Detection

- `ENTRYPOINT ` 다음이 `[`으로 시작하지 않음

### Why

REL-001과 동일한 이유로 shell form의 ENTRYPOINT는 PID 1을 sh로 만들어 시그널 전달을 차단한다. ENTRYPOINT는 거의 항상 exec form을 사용해야 한다.

### Bad

```dockerfile
ENTRYPOINT /app/entrypoint.sh
```

### Good

```dockerfile
ENTRYPOINT ["/app/entrypoint.sh"]
```

---

## DFO-REL-003: WORKDIR not set

**Severity:** minor
**Deduction:** -2

### Detection

- Dockerfile 어디에도 `WORKDIR` 지시어가 없음

### Why

기본 작업 디렉토리는 `/`이다. 로그, 임시 파일, 코어 덤프가 루트에 생성되면 파일시스템 권한 및 소유권 문제가 발생할 수 있다. 명시적인 `WORKDIR /app` 설정을 권장한다.

### Good

```dockerfile
WORKDIR /app
```

---

## DFO-REL-004: Server-like CMD without EXPOSE

**Severity:** minor
**Deduction:** -2

### Detection

- CMD 또는 ENTRYPOINT에 다음 중 하나 포함: `server`, `serve`, `listen`, `:80`, `:8080`, `:3000`, `:5000`, `uvicorn`, `gunicorn`, `nginx`, `httpd`
- AND Dockerfile에 `EXPOSE` 라인이 없음

### Why

`EXPOSE`는 문서화 역할을 하며 `docker run -P` 및 Kubernetes가 컨테이너 포트를 추론하는 데 사용한다. 누락 시 운영 환경에서 포트 매핑 실수가 발생할 수 있다.

### Bad

```dockerfile
FROM node:20-slim
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
USER node
CMD ["node", "server.js"]
```

`server.js`는 `:3000`을 listen하지만 `EXPOSE` 누락 → `docker run -P` 시 자동 매핑 안 됨.

### Good

```dockerfile
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

---

## DFO-REL-005: HEALTHCHECK missing (informational)

**Severity:** info
**Deduction:** 0

### Detection

- Dockerfile에 `HEALTHCHECK` 라인이 없음

### Why

Kubernetes, ECS, Nomad 등 오케스트레이터는 자체 liveness/readiness probe로 health check를 관리하므로 Dockerfile HEALTHCHECK는 중복될 수 있다. standalone docker compose, 로컬 데모, CI 환경에서는 유용하다.

선택 사항: 오케스트레이터가 health check를 관리 중이면 생략 가능.

### Good (필요한 경우)

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q --spider http://localhost:3000/health || exit 1
```

---

## DFO-REL-006: Missing standard runtime env vars

**Severity:** minor
**Deduction:** -2

### Detection

스택별 필수 환경 변수 누락:

- Node.js: 런타임 스테이지에 `NODE_ENV=production` 없음
- Python: `PYTHONUNBUFFERED=1` 없음 (로그 버퍼링 문제)
- Python: `PYTHONDONTWRITEBYTECODE=1` 없음 (info-only, 감점 없음)

### Why

`NODE_ENV`가 설정되지 않으면 일부 npm 패키지가 dev 모드로 동작한다. `PYTHONUNBUFFERED`가 설정되지 않으면 stdout이 버퍼링되어 컨테이너 로그가 지연 출력된다.

### Bad

Node.js — `NODE_ENV` 미설정:
```dockerfile
FROM node:20-slim
WORKDIR /app
COPY . .
RUN npm ci --omit=dev
CMD ["node", "dist/main.js"]
```

Python — `PYTHONUNBUFFERED` 미설정 → 로그 지연:
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "main.py"]
```

### Good (Node.js)

```dockerfile
ENV NODE_ENV=production
```

### Good (Python)

```dockerfile
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1
```
