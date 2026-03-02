FROM ghcr.io/laboratorys/lunatv:dev AS lunatv-source

FROM node:20-alpine AS runner

# 1. 基础环境准备
RUN apk add --no-cache zlib libc6-compat curl zip unzip ca-certificates sqlite tzdata gcompat
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone && apk del tzdata

# 2. 创建 Choreo 用户
RUN addgroup -g 10014 choreo && \
    adduser --disabled-password --no-create-home --uid 10014 --ingroup choreo choreouser

WORKDIR /app

# 3. 备份工具
ARG BAK_VERSION=2.2
RUN curl -L "https://github.com/laboratorys/backup2gh/releases/download/v${BAK_VERSION}/backup2gh-linux-amd64.tar.gz" -o backup2gh.tar.gz \
    && tar -xzf backup2gh.tar.gz && rm backup2gh.tar.gz && chmod +x backup2gh

# 4. 【核心改进】无损全量复制
# 注意：不指定目录，直接从源镜像的工作目录全量拷贝，包括隐藏文件（.next等）
COPY --from=lunatv-source --chown=10014:10014 /app/. .

# 5. 权限彻底修复（排除可执行位干扰，仅保留 755）
USER root
RUN chown -R 10014:10014 /app && \
    find /app -type d -exec chmod 755 {} + && \
    find /app -type f -exec chmod 644 {} + && \
    chmod +x /app/backup2gh /app/scripts/*.sh 2>/dev/null || true

# 6. 确保数据目录
RUN mkdir -p /app/data && chown -R 10014:10014 /app/data

ENV NODE_ENV=production \
    HOSTNAME=0.0.0.0 \
    PORT=3000 \
    DOCKER_ENV=true \
    SQLITE_PATH=/app/data/tv.db

USER 10014
VOLUME /app/data
EXPOSE 3000

# 7. 使用 sh 引导，防止路径解析失败
CMD ["/bin/sh", "-c", "node start.js"]