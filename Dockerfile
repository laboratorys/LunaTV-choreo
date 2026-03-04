FROM ghcr.io/laboratorys/lunatv:dev AS lunatv-source

FROM node:20-alpine AS runner

RUN apk add --no-cache curl unzip sqlite ca-certificates tzdata bash

RUN apk add --no-cache gcompat

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone

RUN addgroup -g 10014 choreo && \
    adduser -u 10014 -G choreo -s /bin/bash -D choreouser

WORKDIR /app

COPY --from=lunatv-source --chown=10014:10014 /app /app

ARG BAK_VERSION=2.3
RUN curl -L "https://github.com/laboratorys/backup2gh/releases/download/v${BAK_VERSION}/backup2gh-linux-amd64.tar.gz" -o backup2gh.tar.gz \
    && tar -xzf backup2gh.tar.gz && rm backup2gh.tar.gz \
    && chmod +x backup2gh && chown 10014:10014 backup2gh

ENV NODE_ENV=production \
    HOSTNAME=0.0.0.0 \
    PORT=3000 \
    DOCKER_ENV=true \
    SQLITE_PATH=/app/data/tv.db

COPY entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

RUN mkdir -p /app/data /app/.next /app/public && \
    chown -R 10014:10014 /app/data /app/.next /app/public


RUN rm -rf /app/public/manifest.json /app/.next/cache && \
    ln -sf /app/data/manifest.json /app/public/manifest.json && \
    ln -sf /app/data/next-cache /app/.next/cache && \
    chown -h 10014:10014 /app/public/manifest.json /app/.next/cache

USER 10014
WORKDIR /app

ENTRYPOINT ["bash", "/app/entrypoint.sh"]