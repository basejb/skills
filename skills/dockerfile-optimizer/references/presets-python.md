# Python Dockerfile Presets

`language=python` 판정 시 사용. 패키지 매니저별 분기 + multi-stage 표준 권장.

---

## pip + requirements.txt + multi-stage

```dockerfile
# syntax=docker/dockerfile:1.7

FROM python:3.12-slim AS builder
WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

COPY requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --user --no-warn-script-location -r requirements.txt

COPY . .

FROM python:3.12-slim AS runner
WORKDIR /app
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH=/root/.local/bin:$PATH

COPY --from=builder /root/.local /root/.local
COPY --from=builder /app /app

RUN useradd -r -s /sbin/nologin app
USER app
EXPOSE 8000
CMD ["python", "-m", "app.main"]
```

---

## poetry + multi-stage

```dockerfile
# syntax=docker/dockerfile:1.7

FROM python:3.12-slim AS builder
WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_CREATE=false \
    POETRY_VERSION=1.8.3

RUN pip install --no-cache-dir poetry==$POETRY_VERSION

COPY pyproject.toml poetry.lock ./
RUN --mount=type=cache,target=/root/.cache/pypoetry \
    poetry install --no-root --only main

COPY . .
RUN poetry install --only main

FROM python:3.12-slim AS runner
WORKDIR /app
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /app /app

RUN useradd -r -s /sbin/nologin app
USER app
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## uv + multi-stage

`uv`는 매우 빠른 Rust 기반 매니저. 컨테이너 빌드에 추천.

```dockerfile
# syntax=docker/dockerfile:1.7

FROM python:3.12-slim AS builder
WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_SYSTEM_PYTHON=1 \
    UV_LINK_MODE=copy

COPY --from=ghcr.io/astral-sh/uv:0.4 /uv /uvx /usr/local/bin/

COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-install-project

COPY . .
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

FROM python:3.12-slim AS runner
WORKDIR /app
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH=/app/.venv/bin:$PATH

COPY --from=builder /app /app

RUN useradd -r -s /sbin/nologin app
USER app
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## Django 변형 (collectstatic 단계 추가)

위 템플릿의 builder stage 끝에:

```dockerfile
RUN python manage.py collectstatic --noinput
```

runner stage에 static 파일 복사:

```dockerfile
COPY --from=builder /app/staticfiles /app/staticfiles
```
