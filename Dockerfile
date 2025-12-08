###############################################################################
# memos构建
###############################################################################
# 1)memos前端构建
FROM --platform=$BUILDPLATFORM node:22-alpine AS frontend
WORKDIR /build/memos/web
COPY memos/web ./
RUN corepack enable && \
    pnpm install --frozen-lockfile && \
    pnpm release && \
    rm -rf ~/.pnpm-store
# 2)memos后端构建
FROM golang:1.25-alpine AS backend
WORKDIR /build/memos
COPY memos/go.mod memos/go.sum ./
RUN go mod download
COPY memos/ .
COPY --from=frontend /build/memos/server/router/frontend/dist ./server/router/frontend/dist
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o memos ./cmd/memos
# memosgram构建
FROM golang:1.25-alpine AS builder
WORKDIR /build/memogram
COPY memogram/go.mod memogram/go.sum ./
RUN go mod download
COPY memogram/ .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o memogram ./bin/memogram
RUN chmod +x memogram
# 运行阶段
FROM alpine:latest
WORKDIR /usr/local/memos
RUN apk add --no-cache tzdata && \
    rm -rf /var/cache/apk/* /tmp/*
COPY --from=backend /build/memos /usr/local/memos/
COPY entrypoint.sh /usr/local/memos/
RUN chmod +x /usr/local/memos/entrypoint.sh
COPY --from=builder /build/memogram/memogram /usr/local/memos/memogram
EXPOSE 5230
RUN mkdir -p /var/opt/memos
VOLUME /var/opt/memos
ENV TZ="Asia/Singapore" \
	MEMOS_MODE=prod \
	MEMOS_PORT=5230 \
	SERVER_ADDR=dns:localhost:5230 \
	BOT_TOKEN=""
ENTRYPOINT ["./entrypoint.sh", "./memos"]
