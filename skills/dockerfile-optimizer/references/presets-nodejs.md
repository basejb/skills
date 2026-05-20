# Node.js Dockerfile Presets

`scripts/detect-stack.sh`가 `language=node`로 판정했을 때 사용할 개선 Dockerfile 템플릿. 패키지 매니저 별로 분기하고, `has_native_deps=true`면 alpine 변종은 제안하지 않는다.

리포트에 사용 시: 사용자 프로젝트의 빌드 명령(`npm run build` 등)을 보고 변형하라. 단순 복사 금지.

---

## npm + multi-stage (기본)

```dockerfile
# syntax=docker/dockerfile:1.7

FROM node:20-slim AS builder
WORKDIR /app

COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

COPY . .
RUN npm run build

FROM node:20-slim AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

COPY --from=builder /app/dist ./dist

USER node
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

---

## pnpm + multi-stage

```dockerfile
# syntax=docker/dockerfile:1.7

FROM node:20-slim AS builder
WORKDIR /app
RUN corepack enable

COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile

COPY . .
RUN pnpm run build

FROM node:20-slim AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN corepack enable

COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --prod --frozen-lockfile

COPY --from=builder /app/dist ./dist

RUN addgroup --system app && adduser --system --ingroup app app
USER app
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

---

## yarn + multi-stage

```dockerfile
# syntax=docker/dockerfile:1.7

FROM node:20-slim AS builder
WORKDIR /app

COPY package.json yarn.lock ./
RUN --mount=type=cache,target=/usr/local/share/.cache/yarn \
    yarn install --frozen-lockfile

COPY . .
RUN yarn build

FROM node:20-slim AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY package.json yarn.lock ./
RUN --mount=type=cache,target=/usr/local/share/.cache/yarn \
    yarn install --frozen-lockfile --production

COPY --from=builder /app/dist ./dist

USER node
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

---

## Next.js standalone 변형

`next.config.js`에 `output: 'standalone'` 설정이 있을 때:

```dockerfile
# syntax=docker/dockerfile:1.7

FROM node:20-slim AS builder
WORKDIR /app
RUN corepack enable

COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile

COPY . .
RUN pnpm run build

FROM node:20-slim AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

USER node
EXPOSE 3000
CMD ["node", "server.js"]
```

---

## Native deps (bcrypt, sharp, canvas 등) 변형

`has_native_deps=true`면 alpine 사용 금지. slim도 일부 모듈은 빌드 도구 필요할 수 있다.

```dockerfile
FROM node:20-slim AS builder
WORKDIR /app

# build-essential은 builder stage에서만
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 make g++ \
 && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:20-slim AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY --from=builder /app/dist ./dist

USER node
EXPOSE 3000
CMD ["node", "dist/main.js"]
```
