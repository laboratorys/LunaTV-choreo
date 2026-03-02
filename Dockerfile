# 1. 明确使用 dev 标签
FROM ghcr.io/laboratorys/lunatv:dev AS lunatv-source

FROM node:20-alpine AS runner

RUN apk add --no-cache zlib libc6-compat curl zip unzip ca-certificates sqlite tzdata

RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata

RUN addgroup -g 10014 choreo && \
    adduser --disabled-password --no-create-home --uid 10014 --ingroup choreo choreouser

WORKDIR /app

# 备份工具下载
ARG BAK_VERSION=2.2
RUN curl -L "https://github.com/laboratorys/backup2gh/releases/download/v${BAK_VERSION}/backup2gh-linux-amd64.tar.gz" -o backup2gh.tar.gz \
    && tar -xzf backup2gh.tar.gz \
    && rm backup2gh.tar.gz \
    && chmod +x backup2gh \
    && chown 10014:10014 backup2gh

# --- 关键修正：全量尝试复制 ---
# 如果 /app 找不到，说明原作者可能没把文件放在 /app 目录。
# 我们从源镜像的工作目录复制所有内容到当前工作目录
COPY --from=lunatv-source --chown=10014:10014 /app/ ./

# 诊断步骤：这行非常重要！请在 Choreo 构建日志里找这部分的输出
RUN echo "Checking files in /app:" && ls -R /app

# 确保数据目录
RUN mkdir -p /app/data && chown -R 10014:10014 /app/data

ENV NODE_ENV=production \
    HOSTNAME=0.0.0.0 \
    PORT=3000 \
    DOCKER_ENV=true \
    SQLITE_PATH=/app/data/tv.db

USER 10014
VOLUME /app/data
EXPOSE 3000

# 启动
CMD ["node", "start.js"]