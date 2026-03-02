# 阶段 1: 引用源镜像
FROM ghcr.io/laboratorys/lunatv:dev AS lunatv-source

# 阶段 2: 运行镜像 (强烈建议用 slim 解决二进制兼容问题)
FROM node:20-slim AS runner

# 安装基础依赖
RUN apt-get update && apt-get install -y \
    curl unzip sqlite3 ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone

# 创建 Choreo 用户
RUN groupadd -g 10014 choreo && \
    useradd --shell /bin/bash -u 10014 -g choreo -m choreouser

WORKDIR /app

# --- 核心修正：自动对齐源镜像工作目录 ---
# 注意 COPY 后面两个点之间的空格。
# 第一个点代表源镜像的 WORKDIR，第二个点代表当前镜像的 WORKDIR。
COPY --from=lunatv-source --chown=10014:10014 . .

# 确保数据目录（即使上面复制失败，这里也保底创建一个）
RUN mkdir -p /app/data && chown -R 10014:10014 /app/data

# 下载备份工具
ARG BAK_VERSION=2.2
RUN curl -L "https://github.com/laboratorys/backup2gh/releases/download/v${BAK_VERSION}/backup2gh-linux-amd64.tar.gz" -o backup2gh.tar.gz \
    && tar -xzf backup2gh.tar.gz && rm backup2gh.tar.gz \
    && chmod +x backup2gh && chown 10014:10014 backup2gh

ENV NODE_ENV=production \
    HOSTNAME=0.0.0.0 \
    PORT=3000 \
    DOCKER_ENV=true \
    SQLITE_PATH=/app/data/tv.db

USER 10014
VOLUME /app/data
EXPOSE 3000

# 启动诊断：这次我们要看看到底抓到了什么
CMD ["/bin/sh", "-c", "echo 'Found Files:' && ls -F && node start.js"]