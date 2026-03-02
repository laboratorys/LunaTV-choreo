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

COPY --from=lunatv-source /app ./
RUN chown -R 10014:10014 /app && \
    chmod -R 755 /app \

RUN echo "Checking files in /app:" && ls -R /app

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