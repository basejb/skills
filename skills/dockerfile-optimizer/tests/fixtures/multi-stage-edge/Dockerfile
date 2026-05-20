FROM node:20-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM deps AS final
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["node", "dist/main.js"]
