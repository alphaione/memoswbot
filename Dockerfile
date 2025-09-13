###############################################################################
# 1) 统一编译阶段
###############################################################################
FROM --platform=$BUILDPLATFORM node:20-alpine AS frontend
WORKDIR /build/memos/web
COPY memos/web ./
RUN corepack enable && corepack prepare pnpm@latest --activate && \
    pnpm install --frozen-lockfile && \
    pnpm release && \
    rm -rf ~/.pnpm-store
# 后端构建
FROM golang:1.24-alpine AS builder
WORKDIR /build/memos
COPY memos/go.mod memos/go.sum ./
RUN go mod download
COPY memos/ .
COPY --from=frontend /build/memos/server/router/frontend/dist ./server/router/frontend/dist
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o memos ./bin/memos/main.go
# memogram
WORKDIR /build/memogram
COPY memogram/go.mod memogram/go.sum ./
RUN go mod download
COPY memogram/ .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o memogram ./bin/memogram

###############################################################################
# 2) 运行阶段：alpine 极简版
###############################################################################
FROM alpine:latest

RUN apk add --no-cache tzdata && \
    rm -rf /var/cache/apk/* /tmp/*

WORKDIR /usr/local/memos

COPY --from=builder /build/memos/memos       ./
COPY --from=builder /build/memogram/memogram /usr/local/bin/memogram
COPY memos/scripts/entrypoint.sh             ./

RUN mkdir -p /var/opt/memos
VOLUME /var/opt/memos

EXPOSE 5230
ENV MEMOS_MODE=prod \
	MEMOS_PORT=5230 \
	SERVER_ADDR=dns:localhost:5230 \
	BOT_TOKEN=your_telegram_bot_token

ENTRYPOINT ["sh","-c", "\
  ./entrypoint.sh ./memos & MEMOS_PID=$!; \
  [ -n \"$BOT_TOKEN\" ] && /usr/local/bin/memogram & MEMOGRAM_PID=$!; \
  trap 'kill -TERM $MEMOS_PID ${MEMOGRAM_PID:-}; wait' TERM; \
  wait \
"]
