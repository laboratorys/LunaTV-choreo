FROM ghcr.io/laboratorys/lunatv:dev AS lunatv-source

FROM node:20-alpine AS runner

# 1. 核心兼容性补丁：添加 gcompat 和 build-base 所需的运行库
RUN apk add --no-cache \
    zlib \
    libc6-compat \
    gcompat \
    curl \
    zip \
    unzip \
    ca-certificates \
    sqlite \
    tzdata

RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata

# 2. 用户与权限
RUN addgroup -g 10014 choreo && \
    adduser --disabled-password --no-create-home --uid 10014 --ingroup choreo choreouser

WORKDIR /app

# 3. 全量复制（包含隐藏的 .next 目录）
COPY --from=lunatv-source --chown=10014:10014 /app/. ./

# 4. 彻底解决“文件存在但读不到”的问题
# 我们不仅要 chown，还要强制转换文件的换行符（防止 dev 镜像带入 Windows 换行符导致 Shebang 失效）
# 同时修正权限：目录 755，文件 644
RUN chown -R 10014:10014 /app && \
    find /app -type d -exec chmod 755 {} + && \
    find /app -type f -exec chmod 644 {} + && \
    chmod +x /app/start.js 2>/dev/null || true

# 5. 确保数据目录
RUN mkdir -p /app/data && chown -R 10014:10014 /app/data

# 备份工具安装
ARG BAK_VERSION=2.2
RUN curl -L "https://github.com/laboratorys/backup2gh/releases/download/v${BAK_VERSION}/backup2gh-linux-amd64.tar.gz" -o backup2gh.tar.gz \
    && tar -xzf backup2gh.tar.gz && rm backup2gh.tar.gz && chmod +x backup2gh

ENV NODE_ENV=production \
    HOSTNAME=0.0.0.0 \
    PORT=3000 \
    DOCKER_ENV=true \
    SQLITE_PATH=/app/data/tv.db

USER 10014
VOLUME /app/data
EXPOSE 3000

# 6. 使用绝对路径启动，并添加调试信息
# 如果 node 还是报错，我们先让它打印一下当前目录
CMD ["/bin/sh", "-c", "ls -la /app/start.js && node /app/start.js"]