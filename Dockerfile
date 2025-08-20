# ---------- Stage 1: 编译 Memos ----------
FROM golang:alpine AS memos-builder
WORKDIR /src/memos
COPY memos/ .
# 静态编译，生成无依赖二进制
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o memos ./cmd/memos

# ---------- Stage 2: 编译 Memogram ----------
FROM node:18-alpine AS memogram-builder
WORKDIR /src/memogram
COPY memogram/ .
RUN npm ci --production && npm run build

# ---------- Stage 3: 运行阶段 ----------
FROM alpine:latest
WORKDIR /
# 只安装必要工具
RUN apk --no-cache add ca-certificates
# 2) 拷贝二进制
COPY --from=memos-builder /src/memos/memos /memos

# 3) 拷贝前端静态文件
COPY --from=memogram-builder /src/memogram/dist /www

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# 4) 暴露端口
EXPOSE 5230
# 5) 直接运行，无 shell
ENTRYPOINT ["./entrypoint.sh", "./memos"]
# memos 默认会把 sqlite 数据写在 /data，使用卷挂载即可
VOLUME ["/data"]