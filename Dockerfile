FROM ghcr.io/laboratorys/lunatv:f AS lunatv-source

FROM node:20-alpine AS runner

RUN apk add --no-cache \
    zlib \
    libc6-compat \
    curl \
    zip \
    unzip \
    ca-certificates \
    sqlite \
    tzdata

RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata

RUN addgroup -g 10014 choreo && \
    adduser --disabled-password --no-create-home --uid 10014 --ingroup choreo choreouser

WORKDIR /app

# 确保在构建阶段就创建好所有可能写入的目录
RUN mkdir -p /app/data /app/.next/cache && chown -R 10014:10014 /app

ARG BAK_VERSION=2.2
RUN curl -L "https://github.com/laboratorys/backup-to-github/releases/download/v${BAK_VERSION}/backup2gh-v${BAK_VERSION}-linux-amd64.tar.gz" -o backup-to-github.tar.gz \
    && tar -xzf backup-to-github.tar.gz \
    && rm backup-to-github.tar.gz \
    && chmod +x backup2gh \
    && chown 10014:10014 backup2gh

# 复制程序文件并确保权限
COPY --from=lunatv-source --chown=10014:10014 /app/.next/standalone ./
COPY --from=lunatv-source --chown=10014:10014 /app/scripts ./scripts
COPY --from=lunatv-source --chown=10014:10014 /app/start.js ./start.js
COPY --from=lunatv-source --chown=10014:10014 /app/public ./public
COPY --from=lunatv-source --chown=10014:10014 /app/.next/static ./.next/static

ENV NODE_ENV=production \
    HOSTNAME=0.0.0.0 \
    PORT=3000 \
    DOCKER_ENV=true \
    SQLITE_PATH=/app/data/tv.db

USER 10014
VOLUME /app/data
EXPOSE 3000

CMD ["node", "start.js"]