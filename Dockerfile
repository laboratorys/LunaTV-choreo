FROM ghcr.io/laboratorys/lunatv:dev AS lunatv-source

FROM node:20-alpine AS runner

RUN apk add --no-cache zlib libc6-compat curl zip unzip ca-certificates sqlite tzdata

RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata

RUN addgroup -g 10014 choreo && \
    adduser --disabled-password --no-create-home --uid 10014 --ingroup choreo choreouser

WORKDIR /app

# 下载备份工具
ARG BAK_VERSION=2.2
RUN curl -L "https://github.com/laboratorys/backup2gh/releases/download/v${BAK_VERSION}/backup2gh-linux-amd64.tar.gz" -o backup2gh.tar.gz \
    && tar -xzf backup2gh.tar.gz \
    && rm backup2gh.tar.gz \
    && chmod +x backup2gh

# 复制源镜像所有文件
COPY --from=lunatv-source /app ./

# 修正：语法分开，确保所有权和权限彻底刷新
RUN chown -R 10014:10014 /app && \
    chmod -R 755 /app

# 诊断：查看文件是否真的在 /app
RUN echo "Final file check:" && ls -F /app

# 确保数据目录存在
RUN mkdir -p /app/data && chown -R 10014:10014 /app/data

ENV NODE_ENV=production \
    HOSTNAME=0.0.0.0 \
    PORT=3000 \
    DOCKER_ENV=true \
    SQLITE_PATH=/app/data/tv.db

USER 10014
VOLUME /app/data
EXPOSE 3000

# 启动 (使用绝对路径确保万无一失)
CMD ["node", "/app/start.js"]