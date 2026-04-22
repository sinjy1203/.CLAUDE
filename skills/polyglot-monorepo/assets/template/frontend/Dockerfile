# ============================================
# Stage 1: Build
# ============================================
FROM node:20-alpine AS builder

RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm build

# ============================================
# Stage 2: Serve
# ============================================
FROM nginx:alpine AS runner

COPY --from=builder /app/dist /usr/share/nginx/html

# TODO: 필요 시 nginx.conf 커스터마이징
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
